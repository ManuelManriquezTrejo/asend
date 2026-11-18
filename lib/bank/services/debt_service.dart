import 'dart:math';

import 'package:asend/bank/services/account_service.dart';
import 'package:asend/cashout/services/cash_out_config_service.dart';
import 'package:asend/database/debt_hive_service.dart';
import 'package:asend/models/debt.dart';
import 'package:asend/models/debt_installment.dart';

/// Lógica de Deuda: suscripciones, gastos a meses y pagos únicos.
///
/// Cada deuda genera mensualidades ([DebtInstallment]). Pagar descuenta
/// de una cuenta con aplicarMovimiento, así que cada pago queda en el
/// historial de Banco como "Pago de deuda".
class DebtService {
  static const String recurrente = 'recurrente';
  static const String gasto = 'gasto';
  static const String unico = 'unico';

  /// Meses que se muestran después del último pago pendiente.
  static const int mesesExtra = 3;

  /// Suscripciones: cuántos pagos pendientes se muestran como mínimo.
  static const int pagosMinimosSuscripcion = 3;

  static const String _claveUltimaCuenta = 'ultimaCuentaId';

  // ── Fechas ─────────────────────────────────────────────

  /// Hoy, sin hora.
  static DateTime hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  /// Primer día del mes siguiente al actual. Todo lo que tenga fecha de
  /// pago antes de este día pertenece al mes actual o ya está vencido.
  static DateTime _inicioMesSiguiente() {
    final h = hoy();
    return DateTime(h.year, h.month + 1, 1);
  }

  /// Fecha en ese mes con ese día. Si el mes es más corto (día 31 en
  /// noviembre, o 29 a 31 en febrero), se usa el último día del mes.
  /// Un mes mayor a 12 pasa solo al año siguiente.
  static DateTime fechaEnMes(int anio, int mes, int dia) {
    final ultimoDia = DateTime(anio, mes + 1, 0).day;
    return DateTime(anio, mes, min(dia, ultimoDia));
  }

  /// Fecha de pago de la mensualidad [n] de una deuda.
  static DateTime _fechaCuota(Debt d, int n) =>
      fechaEnMes(d.fechaInicio.year, d.fechaInicio.month + n, d.diaPago);

  /// Mes en número continuo (año × 12 + mes), para comparar meses.
  static int _claveMes(DateTime f) => f.year * 12 + f.month;

  // ── Lectura ────────────────────────────────────────────

  static List<Debt> getDeudas() => DebtHiveService.getDebtsBox().values
      .where((d) => d.deletedAt == null)
      .toList();

  /// Una deuda por id, incluso eliminada, para mostrar su nombre.
  static Debt? getDeuda(int id) => DebtHiveService.getDebtsBox().get(id);

  static String nombreDe(DebtInstallment c) =>
      getDeuda(c.debtId)?.nombre ?? 'Pago eliminado';

  static String tipoDe(DebtInstallment c) => getDeuda(c.debtId)?.tipo ?? '';

  static List<Debt> getSuscripciones() =>
      getDeudas().where((d) => d.tipo == recurrente).toList()
        ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

  /// Mensualidades activas (no eliminadas) de una deuda, en orden.
  static List<DebtInstallment> _cuotasDe(int debtId) {
    final cuotas = DebtHiveService.getInstallmentsBox().values
        .where((c) => c.debtId == debtId && c.deletedAt == null)
        .toList();
    cuotas.sort((a, b) => a.numero.compareTo(b.numero));
    return cuotas;
  }

  /// Todas las mensualidades sin pagar de deudas activas, por fecha.
  static List<DebtInstallment> getPendientes() {
    final activas = getDeudas().map((d) => d.id).toSet();

    final pendientes = DebtHiveService.getInstallmentsBox().values
        .where(
          (c) =>
              c.deletedAt == null &&
              c.pagadoAt == null &&
              activas.contains(c.debtId),
        )
        .toList();

    pendientes.sort((a, b) => a.fechaPago.compareTo(b.fechaPago));
    return pendientes;
  }

  /// Mensualidades sin pagar de una deuda.
  static List<DebtInstallment> pendientesDe(int debtId) =>
      _cuotasDe(debtId).where((c) => c.pagadoAt == null).toList();

  /// True si la fecha de pago ya pasó (antes de hoy) y no se ha pagado.
  /// Se guarda como cálculo para las notificaciones futuras.
  static bool estaVencida(DebtInstallment c) =>
      c.pagadoAt == null && c.fechaPago.isBefore(hoy());

  // ── Resumen del recuadro de Banco ──────────────────────

  /// Mensualidades de tarjeta y pagos únicos pendientes, más las
  /// suscripciones del mes actual o vencidas. Las suscripciones de
  /// meses futuros todavía no cuentan.
  static double deudaTotal() {
    final limite = _inicioMesSiguiente();

    return getPendientes()
        .where((c) => tipoDe(c) != recurrente || c.fechaPago.isBefore(limite))
        .fold<double>(0, (s, c) => s + c.monto);
  }

  /// Todo lo que vence este mes, más lo vencido sin pagar.
  static double pagoDelMes() {
    final limite = _inicioMesSiguiente();

    return getPendientes()
        .where((c) => c.fechaPago.isBefore(limite))
        .fold<double>(0, (s, c) => s + c.monto);
  }

  /// La mensualidad pendiente más cercana, incluso si ya venció.
  static DebtInstallment? proximoPago() {
    final pendientes = getPendientes();
    return pendientes.isEmpty ? null : pendientes.first;
  }

  /// Pendientes con fecha de pago hoy o antes. Encienden el punto rojo
  /// y aparecen en el inicio dentro de Misiones.
  static List<DebtInstallment> pagosParaHoy() {
    final manana = hoy().add(const Duration(days: 1));
    return getPendientes().where((c) => c.fechaPago.isBefore(manana)).toList();
  }

  static bool hayPagoParaHoy() => pagosParaHoy().isNotEmpty;

  // ── Suscripciones: crear mensualidades conforme se necesitan ──

  /// Crea las mensualidades de las suscripciones que falten hasta donde
  /// se muestran: el último pago pendiente de tarjeta o único más 3
  /// meses, y al menos 3 pagos pendientes por suscripción.
  /// Se llama antes de leer pendientes para la pantalla de Pagar y para
  /// el recuadro de Banco.
  static Future<void> generarSuscripciones() async {
    final limite = _claveMes(_horizonteSinSuscripciones());

    for (final d in getSuscripciones()) {
      final cuotas = _cuotasDe(d.id);
      var siguiente = cuotas.isEmpty ? 0 : cuotas.last.numero + 1;
      var pendientes = cuotas.where((c) => c.pagadoAt == null).length;

      // Crear hasta cubrir el horizonte, la fecha de hoy y el mínimo
      // de pagos pendientes. El tope de 600 evita un ciclo infinito.
      while (siguiente < 600) {
        final fecha = _fechaCuota(d, siguiente);
        final cubreHorizonte = _claveMes(fecha) > limite;
        final cubreHoy = fecha.isAfter(hoy());

        if (cubreHorizonte &&
            cubreHoy &&
            pendientes >= pagosMinimosSuscripcion) {
          break;
        }

        await _crearCuota(d, siguiente, d.monto, fecha);
        siguiente++;
        pendientes++;
      }
    }
  }

  /// Último mes con pago pendiente de tarjeta o único, más 3 meses.
  /// Sin pendientes de ese tipo, el mes actual más 3.
  static DateTime _horizonteSinSuscripciones() {
    final sinSuscripciones = getPendientes()
        .where((c) => tipoDe(c) != recurrente)
        .toList();

    final base = sinSuscripciones.isEmpty
        ? hoy()
        : sinSuscripciones.last.fechaPago;

    return DateTime(base.year, base.month + mesesExtra, 1);
  }

  /// Pendientes que se muestran en la pantalla de Pagar. Las
  /// suscripciones se recortan al horizonte, pero cada una conserva
  /// al menos sus 3 próximos pagos.
  static List<DebtInstallment> getPendientesParaLista() {
    final limite = _claveMes(_horizonteSinSuscripciones());
    final vistosPorDeuda = <int, int>{};

    return getPendientes().where((c) {
      if (tipoDe(c) != recurrente) return true;

      final vistos = vistosPorDeuda[c.debtId] ?? 0;
      vistosPorDeuda[c.debtId] = vistos + 1;

      return _claveMes(c.fechaPago) <= limite ||
          vistos < pagosMinimosSuscripcion;
    }).toList();
  }

  // ── Crear ──────────────────────────────────────────────

  static int _siguienteIdDeuda() {
    final box = DebtHiveService.getDebtsBox();
    return box.isEmpty ? 1 : box.values.map((d) => d.id).reduce(max) + 1;
  }

  static int _siguienteIdCuota() {
    final box = DebtHiveService.getInstallmentsBox();
    return box.isEmpty ? 1 : box.values.map((c) => c.id).reduce(max) + 1;
  }

  static Future<void> _crearCuota(
    Debt d,
    int numero,
    double monto,
    DateTime fechaPago,
  ) async {
    final box = DebtHiveService.getInstallmentsBox();
    final id = _siguienteIdCuota();

    await box.put(
      id,
      DebtInstallment(
        id: id,
        debtId: d.id,
        numero: numero,
        monto: monto,
        fechaPago: fechaPago,
        fechaLimite: fechaPago.add(Duration(days: d.diasLimite)),
      ),
    );
  }

  /// Reparte un total en mensualidades iguales, en centavos para no
  /// perder decimales. La última absorbe la diferencia: \$1,000 en 3
  /// meses son 333.33, 333.33 y 333.34.
  static List<double> repartir(double total, int meses) {
    final totalCentavos = (total * 100).round();
    final baseCentavos = totalCentavos ~/ meses;
    final ultimaCentavos = totalCentavos - baseCentavos * (meses - 1);

    return [
      for (var i = 0; i < meses - 1; i++) baseCentavos / 100,
      ultimaCentavos / 100,
    ];
  }

  /// Revisa los datos comunes. Devuelve el error, o null si sirven.
  static String? _validar({
    required String nombre,
    required double monto,
    required DateTime fechaPago,
    required DateTime fechaLimite,
  }) {
    if (nombre.trim().isEmpty) return 'Escribe un nombre';
    if (monto <= 0) return 'El monto debe ser mayor a 0';
    if (fechaLimite.isBefore(fechaPago)) {
      return 'La fecha límite no puede ser antes de la fecha de pago';
    }
    return null;
  }

  /// Guarda un pago nuevo y sus mensualidades.
  /// [monto] es el pago mensual en suscripción, el total en gasto y el
  /// pago completo en único. Devuelve null si salió bien, o el error.
  static Future<String?> crear({
    required String tipo,
    required String nombre,
    required double monto,
    required DateTime fechaPago,
    required DateTime fechaLimite,
    int meses = 0,
  }) async {
    final error = _validar(
      nombre: nombre,
      monto: monto,
      fechaPago: fechaPago,
      fechaLimite: fechaLimite,
    );
    if (error != null) return error;
    if (tipo == gasto && meses < 1) return 'Escribe cuántos meses dura';

    final pago = DateTime(fechaPago.year, fechaPago.month, fechaPago.day);
    final limite = DateTime(
      fechaLimite.year,
      fechaLimite.month,
      fechaLimite.day,
    );

    final montos = tipo == gasto ? repartir(monto, meses) : [monto];

    final deuda = Debt(
      id: _siguienteIdDeuda(),
      nombre: nombre.trim(),
      tipo: tipo,
      monto: montos.first,
      diaPago: pago.day,
      diasLimite: limite.difference(pago).inDays,
      fechaInicio: pago,
      meses: tipo == gasto ? meses : 0,
      createdAt: DateTime.now(),
    );
    await DebtHiveService.getDebtsBox().put(deuda.id, deuda);

    if (tipo == recurrente) {
      await generarSuscripciones();
    } else {
      for (var n = 0; n < montos.length; n++) {
        await _crearCuota(deuda, n, montos[n], _fechaCuota(deuda, n));
      }
    }

    return null;
  }

  // ── Editar ─────────────────────────────────────────────

  /// Cambia una deuda. Solo afecta lo que no se ha pagado.
  ///
  /// - Suscripción: nombre, monto y día. Las mensualidades pendientes
  ///   toman el monto nuevo y el día nuevo dentro de su mismo mes.
  /// - Gasto: [meses] son los que faltan y [monto] el total que falta.
  ///   Las pendientes se reemplazan por mensualidades nuevas desde
  ///   [fechaPago].
  /// - Único: nombre, monto y fecha.
  static Future<String?> editar({
    required int debtId,
    required String nombre,
    required double monto,
    required DateTime fechaPago,
    required DateTime fechaLimite,
    int meses = 0,
  }) async {
    final deuda = getDeuda(debtId);
    if (deuda == null || deuda.deletedAt != null) {
      return 'Ese pago ya no existe';
    }

    final error = _validar(
      nombre: nombre,
      monto: monto,
      fechaPago: fechaPago,
      fechaLimite: fechaLimite,
    );
    if (error != null) return error;
    if (deuda.tipo == gasto && meses < 1) {
      return 'Escribe cuántos meses faltan';
    }

    final pago = DateTime(fechaPago.year, fechaPago.month, fechaPago.day);
    final limite = DateTime(
      fechaLimite.year,
      fechaLimite.month,
      fechaLimite.day,
    );

    final box = DebtHiveService.getInstallmentsBox();
    final pendientes = pendientesDe(debtId);

    deuda.nombre = nombre.trim();
    deuda.diasLimite = limite.difference(pago).inDays;
    deuda.diaPago = pago.day;

    if (deuda.tipo == gasto) {
      // Las pendientes se eliminan y se crean las nuevas a continuación
      final ahora = DateTime.now();
      for (final c in pendientes) {
        c.deletedAt = ahora;
        await box.put(c.id, c);
      }

      final cuotas = _cuotasDe(debtId);
      final siguiente = cuotas.isEmpty ? 0 : cuotas.last.numero + 1;
      final montos = repartir(monto, meses);

      deuda.monto = montos.first;
      deuda.meses = cuotas.length + meses;
      await DebtHiveService.getDebtsBox().put(deuda.id, deuda);

      for (var i = 0; i < montos.length; i++) {
        await _crearCuota(
          deuda,
          siguiente + i,
          montos[i],
          fechaEnMes(pago.year, pago.month + i, pago.day),
        );
      }
      return null;
    }

    deuda.monto = monto;

    if (deuda.tipo == unico) {
      // El pago único tiene una sola mensualidad: se mueve a la fecha nueva
      deuda.fechaInicio = pago;
      for (final c in pendientes) {
        c.monto = monto;
        c.fechaPago = pago;
        c.fechaLimite = limite;
        await box.put(c.id, c);
      }
    } else {
      // Suscripción: cada pendiente se queda en su mes con el día nuevo
      for (final c in pendientes) {
        c.monto = monto;
        c.fechaPago = fechaEnMes(
          c.fechaPago.year,
          c.fechaPago.month,
          deuda.diaPago,
        );
        c.fechaLimite = c.fechaPago.add(Duration(days: deuda.diasLimite));
        await box.put(c.id, c);
      }
    }

    await DebtHiveService.getDebtsBox().put(deuda.id, deuda);
    return null;
  }

  // ── Eliminar y cancelar ────────────────────────────────

  /// Elimina una deuda sin pagar lo que falta. Las mensualidades ya
  /// pagadas se conservan, y sus pagos siguen en el historial de Banco.
  /// También sirve para cancelar una suscripción.
  static Future<void> eliminar(int debtId) async {
    final deuda = getDeuda(debtId);
    if (deuda == null) return;

    final ahora = DateTime.now();
    final box = DebtHiveService.getInstallmentsBox();

    for (final c in pendientesDe(debtId)) {
      c.deletedAt = ahora;
      await box.put(c.id, c);
    }

    deuda.deletedAt = ahora;
    await DebtHiveService.getDebtsBox().put(deuda.id, deuda);
  }

  // ── Pagar ──────────────────────────────────────────────

  /// Cuenta que aparece elegida al pagar: la última usada. La primera
  /// vez, la cuenta que paga en Pagos. Solo si sigue activa.
  static int? cuentaPorDefecto() {
    final ultima = DebtHiveService.getSettingsBox().get(_claveUltimaCuenta);
    if (ultima is int && AccountService.getAccountById(ultima) != null) {
      return ultima;
    }

    final dePagos = CashOutConfigService.getConfigSync()?.cuentaPagaId;
    if (dePagos != null && AccountService.getAccountById(dePagos) != null) {
      return dePagos;
    }
    return null;
  }

  /// Paga completas las mensualidades marcadas desde una cuenta.
  /// Si el saldo no alcanza para todas, no se paga ninguna.
  /// Cada una queda en el historial como "Pago de deuda: nombre".
  /// Devuelve null si salió bien, o el mensaje de error.
  static Future<String?> pagar({
    required List<DebtInstallment> cuotas,
    required int accountId,
  }) async {
    if (cuotas.isEmpty) return 'Marca al menos un pago';

    final cuenta = AccountService.getAccountById(accountId);
    if (cuenta == null) return 'Esa cuenta ya no existe';

    final total = cuotas.fold<double>(0, (s, c) => s + c.monto);

    // Medio centavo de margen por los decimales de los repartos
    if (cuenta.balance + 0.005 < total) {
      return 'Saldo insuficiente en ${cuenta.name}. '
          'Tiene \$${cuenta.balance.toStringAsFixed(2)} '
          'y el pago es de \$${total.toStringAsFixed(2)}';
    }

    final box = DebtHiveService.getInstallmentsBox();
    final ahora = DateTime.now();

    for (final c in cuotas) {
      final ok = await AccountService.aplicarMovimiento(
        accountId: accountId,
        monto: -c.monto, // sale
        concepto: 'Pago de deuda: ${nombreDe(c)}',
        referenciaId: c.id,
      );
      if (!ok) return 'No se pudo pagar ${nombreDe(c)}';

      c.pagadoAt = ahora;
      c.accountId = accountId;
      await box.put(c.id, c);
    }

    await DebtHiveService.getSettingsBox().put(_claveUltimaCuenta, accountId);
    return null;
  }
}