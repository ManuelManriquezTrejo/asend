import 'package:asend/bank/services/debt_service.dart';
import 'package:asend/models/debt.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Crear un pago nuevo (suscripción, gasto con tarjeta o pago único), o
/// editar uno existente. Al editar, el tipo no cambia y solo se tocan
/// los pagos pendientes. Devuelve true al cerrarse si guardó o eliminó.
class NewDebtScreen extends StatefulWidget {
  /// Con una deuda, la pantalla la edita en lugar de crear una nueva.
  final Debt? editar;

  const NewDebtScreen({super.key, this.editar});

  @override
  State<NewDebtScreen> createState() => _NewDebtScreenState();
}

class _NewDebtScreenState extends State<NewDebtScreen> {
  static const List<String> _mesesCortos = [
    '',
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// Opciones del desplegable, en el orden en que aparecen.
  static const Map<String, String> _tipos = {
    DebtService.recurrente: 'Pago recurrente (suscripción mensual)',
    DebtService.gasto: 'Gasto (deuda con tarjeta de crédito)',
    DebtService.unico: 'Pago único',
  };

  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController(); // Suscripción y pago único
  final _mesesCtrl = TextEditingController(); // Gasto
  final _totalCtrl = TextEditingController(); // Gasto
  final _mensualCtrl = TextEditingController(); // Gasto

  String? _tipo;
  DateTime? _fechaPago;
  DateTime? _fechaLimite;
  bool _guardando = false;

  /// En el gasto, el último campo de dinero que escribió el usuario
  /// manda: si fue el pago mensual se calcula el total, y al revés.
  bool _mandaMensual = false;

  bool get _editando => widget.editar != null;

  @override
  void initState() {
    super.initState();
    final deuda = widget.editar;
    if (deuda != null) _cargar(deuda);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _mesesCtrl.dispose();
    _totalCtrl.dispose();
    _mensualCtrl.dispose();
    super.dispose();
  }

  /// Al editar, llena los campos con lo que falta por pagar.
  void _cargar(Debt d) {
    _tipo = d.tipo;
    _nombreCtrl.text = d.nombre;

    final pendientes = DebtService.pendientesDe(d.id);
    if (pendientes.isNotEmpty) {
      _fechaPago = pendientes.first.fechaPago;
      _fechaLimite = pendientes.first.fechaLimite;
    } else {
      _fechaPago = d.fechaInicio;
      _fechaLimite = d.fechaInicio.add(Duration(days: d.diasLimite));
    }

    if (d.tipo == DebtService.gasto) {
      // Los meses y el total son los que faltan, no los originales
      final total = pendientes.fold<double>(0, (s, c) => s + c.monto);
      _mesesCtrl.text = '${pendientes.length}';
      _totalCtrl.text = _numero(total);
      _mensualCtrl.text = pendientes.isEmpty
          ? ''
          : _numero(pendientes.first.monto);
    } else {
      _montoCtrl.text = _numero(d.monto);
    }
  }

  // ── Formatos ───────────────────────────────────────────

  /// 1000.00 se escribe 1000; 333.33 se queda igual.
  String _numero(double v) =>
      v.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');

  String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

  String _fecha(DateTime d) => '${d.day} ${_mesesCortos[d.month]} ${d.year}';

  /// Convierte el texto a número. Acepta coma o punto como decimal.
  double? _leer(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ── Comportamiento de los campos ───────────────────────

  /// Al cambiar de tipo se borran los campos que desaparecen. El nombre
  /// y las fechas se conservan porque los tres tipos los usan.
  void _cambiarTipo(String? tipo) {
    if (tipo == null || tipo == _tipo) return;

    setState(() {
      if (tipo == DebtService.gasto) {
        _montoCtrl.clear();
      } else {
        _mesesCtrl.clear();
        _totalCtrl.clear();
        _mensualCtrl.clear();
        _mandaMensual = false;
      }
      _tipo = tipo;
    });
  }

  /// Completa el total o el pago mensual del gasto según el último
  /// campo que se escribió.
  void _recalcularGasto() {
    final meses = int.tryParse(_mesesCtrl.text.trim());
    if (meses == null || meses < 1) return;

    if (_mandaMensual) {
      final mensual = _leer(_mensualCtrl);
      _totalCtrl.text = mensual == null ? '' : _numero(mensual * meses);
    } else {
      final total = _leer(_totalCtrl);
      _mensualCtrl.text = total == null
          ? ''
          : _numero(DebtService.repartir(total, meses).first);
    }
  }

  Future<void> _elegirFecha({required bool esLimite}) async {
    final ahora = DateTime.now();
    final primera = DateTime(ahora.year - 2);
    final ultima = DateTime(ahora.year + 10);

    var inicial = (esLimite ? (_fechaLimite ?? _fechaPago) : _fechaPago) ??
        ahora;
    if (inicial.isBefore(primera)) inicial = primera;
    if (inicial.isAfter(ultima)) inicial = ultima;

    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primera,
      lastDate: ultima,
    );
    if (elegida == null || !mounted) return;

    setState(() {
      if (esLimite) {
        _fechaLimite = elegida;
      } else {
        _fechaPago = elegida;
      }
    });
  }

  // ── Guardar ────────────────────────────────────────────

  Future<void> _continuar() async {
    final tipo = _tipo;
    final nombre = _nombreCtrl.text.trim();
    final fechaPago = _fechaPago;
    final fechaLimite = _fechaLimite;

    if (nombre.isEmpty) {
      _aviso('Escribe de qué es el pago');
      return;
    }
    if (tipo == null) {
      _aviso('Elige el tipo de pago');
      return;
    }
    if (fechaPago == null) {
      _aviso('Elige la fecha de pago');
      return;
    }
    if (fechaLimite == null) {
      _aviso('Elige la fecha límite de pago');
      return;
    }

    var meses = 0;
    double? monto;

    if (tipo == DebtService.gasto) {
      meses = int.tryParse(_mesesCtrl.text.trim()) ?? 0;
      if (meses < 1) {
        _aviso('Escribe cuántos meses dura');
        return;
      }
      monto = _leer(_totalCtrl);
    } else {
      monto = _leer(_montoCtrl);
    }

    if (monto == null || monto <= 0) {
      _aviso('Escribe un monto mayor a 0');
      return;
    }
    final montoFinal = monto;

    setState(() => _guardando = true);

    final error = _editando
        ? await DebtService.editar(
            debtId: widget.editar!.id,
            nombre: nombre,
            monto: monto,
            fechaPago: fechaPago,
            fechaLimite: fechaLimite,
            meses: meses,
          )
        : await DebtService.crear(
            tipo: tipo,
            nombre: nombre,
            monto: monto,
            fechaPago: fechaPago,
            fechaLimite: fechaLimite,
            meses: meses,
          );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      _aviso(error);
      return;
    }

    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _editando ? 'Cambios guardados' : 'Pago guardado',
          style: const TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          _confirmacion(tipo, nombre, montoFinal, meses, fechaPago),
          style: TextStyle(color: AppTheme.textGrey, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    navigator.pop(true);
  }

  /// Mensaje que confirma lo que se guardó.
  String _confirmacion(
    String tipo,
    String nombre,
    double monto,
    int meses,
    DateTime fechaPago,
  ) {
    if (_editando) {
      return 'Se guardaron los cambios de "$nombre". '
          'Solo se modificaron los pagos pendientes.';
    }

    if (tipo == DebtService.recurrente) {
      return 'Se ha generado un pago recurrente "$nombre" de '
          '${_dinero(monto)} los días ${fechaPago.day} de cada mes.\n\n'
          'Para eliminar el pago recurrente, ve a Pagar en la sección Banco.';
    }

    if (tipo == DebtService.gasto) {
      final montos = DebtService.repartir(monto, meses);
      var texto =
          'Se generó el gasto "$nombre": a pagar '
          '${_dinero(montos.first)} el día ${fechaPago.day} de cada mes '
          'durante $meses ${meses == 1 ? 'mes' : 'meses'}.';

      if (montos.last != montos.first) {
        texto +=
            '\n\nLa última mensualidad es de ${_dinero(montos.last)} '
            'para que el total cuadre.';
      }
      return texto;
    }

    return 'Se ha guardado un pago de ${_dinero(monto)} '
        'para el día ${_fecha(fechaPago)}.';
  }

  // ── Eliminar (solo al editar) ──────────────────────────

  Future<void> _eliminarSinPagar() async {
    final deuda = widget.editar!;
    final esSuscripcion = deuda.tipo == DebtService.recurrente;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Eliminar "${deuda.nombre}"?',
          style: const TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '${esSuscripcion ? 'Se recomienda cancelar primero la suscripción '
                    'antes de borrar el recordatorio.\n\n' : ''}'
          'Se eliminarán los pagos pendientes sin pagarse. '
          'Lo que ya pagaste se queda en el historial.',
          style: TextStyle(color: AppTheme.textGrey, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await DebtService.eliminar(deuda.id);

    navigator.pop(true);
    messenger.showSnackBar(
      SnackBar(content: Text('"${deuda.nombre}" eliminado')),
    );
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final tipo = _tipo;
    final esGasto = tipo == DebtService.gasto;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar pago' : 'Nuevo pago')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: e.w(5),
                  vertical: e.h(1.5),
                ),
                children: [
                  _campoTexto(
                    e,
                    titulo: '¿De qué es el pago?',
                    ctrl: _nombreCtrl,
                    ejemplo: _ejemploNombre(),
                  ),

                  _titulo(e, 'Tipo de pago'),
                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    isExpanded: true,
                    dropdownColor: AppTheme.bgDarkGrey,
                    decoration: _decoracion(e, ''),
                    hint: Text(
                      'Elige el tipo de pago',
                      style: _estiloEjemplo(e),
                    ),
                    items: _tipos.entries
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t.key,
                            child: Text(
                              t.value,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: e.t(3.8),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    // Al editar, el tipo ya no se puede cambiar
                    onChanged: _editando ? null : _cambiarTipo,
                  ),

                  if (tipo == DebtService.recurrente ||
                      tipo == DebtService.unico)
                    _campoNumero(
                      e,
                      titulo: 'Monto',
                      ctrl: _montoCtrl,
                      ejemplo: tipo == DebtService.recurrente
                          ? 'Ej: 199'
                          : 'Ej: 1500',
                    ),

                  if (esGasto) ...[
                    _campoNumero(
                      e,
                      titulo: _editando
                          ? '¿Cuántos meses faltan?'
                          : '¿Cuántos meses dura?',
                      ctrl: _mesesCtrl,
                      ejemplo: 'Ej: 12',
                      entero: true,
                      onChanged: (_) => _recalcularGasto(),
                    ),
                    _campoNumero(
                      e,
                      titulo: _editando ? 'Monto total que falta' : 'Monto total',
                      ctrl: _totalCtrl,
                      ejemplo: 'Ej: 12000',
                      onChanged: (_) {
                        _mandaMensual = false;
                        _recalcularGasto();
                      },
                    ),
                    _campoNumero(
                      e,
                      titulo: 'Pago a meses (cada mes)',
                      ctrl: _mensualCtrl,
                      ejemplo: 'Ej: 1000',
                      onChanged: (_) {
                        _mandaMensual = true;
                        _recalcularGasto();
                      },
                    ),
                  ],

                  if (tipo != null) ...[
                    _campoFecha(
                      e,
                      titulo: esGasto
                          ? (_editando
                                ? 'Fecha del próximo pago'
                                : 'Fecha del primer pago')
                          : 'Fecha de pago',
                      fecha: _fechaPago,
                      onTap: () => _elegirFecha(esLimite: false),
                    ),
                    _campoFecha(
                      e,
                      titulo: 'Fecha límite de pago',
                      fecha: _fechaLimite,
                      onTap: () => _elegirFecha(esLimite: true),
                    ),
                  ],

                  if (_editando) ...[
                    SizedBox(height: e.h(4)),
                    TextButton.icon(
                      onPressed: _eliminarSinPagar,
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppTheme.danger,
                        size: e.t(5),
                      ),
                      label: Text(
                        'Eliminar sin pagar',
                        style: TextStyle(
                          color: AppTheme.danger,
                          fontSize: e.t(3.8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Botones fijos abajo
            Padding(
              padding: EdgeInsets.fromLTRB(e.w(5), e.h(1), e.w(5), e.h(2)),
              child: Row(
                children: [
                  Flexible(
                    child: SizedBox(
                      width: double.infinity,
                      height: e.h(6.5),
                      child: OutlinedButton(
                        onPressed: _guardando
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.textGrey),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: e.t(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: e.w(4)),
                  Flexible(
                    child: SizedBox(
                      width: double.infinity,
                      height: e.h(6.5),
                      child: ElevatedButton(
                        onPressed: _guardando || tipo == null
                            ? null
                            : _continuar,
                        child: Text(
                          'Continuar',
                          style: TextStyle(fontSize: e.t(4)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ejemploNombre() {
    switch (_tipo) {
      case DebtService.gasto:
        return 'Ej: Televisión a 12 meses';
      case DebtService.unico:
        return 'Ej: Boletos del concierto';
      default:
        return 'Ej: Netflix';
    }
  }

  // ── Piezas de la pantalla ──────────────────────────────

  /// Título de cada campo, arriba del recuadro.
  Widget _titulo(Escala e, String texto) {
    return Padding(
      padding: EdgeInsets.only(top: e.h(2), bottom: e.h(0.8)),
      child: Text(
        texto,
        style: TextStyle(
          color: AppTheme.textWhite,
          fontSize: e.t(4),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Texto de ejemplo en gris claro. Desaparece al escribir.
  TextStyle _estiloEjemplo(Escala e) => TextStyle(
    color: AppTheme.textGrey.withValues(alpha: 0.6),
    fontSize: e.t(3.8),
  );

  InputDecoration _decoracion(Escala e, String ejemplo) {
    return InputDecoration(
      hintText: ejemplo.isEmpty ? null : ejemplo,
      hintStyle: _estiloEjemplo(e),
      contentPadding: EdgeInsets.symmetric(
        horizontal: e.w(4),
        vertical: e.h(1.6),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(e.t(2))),
    );
  }

  Widget _campoTexto(
    Escala e, {
    required String titulo,
    required TextEditingController ctrl,
    required String ejemplo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(e, titulo),
        TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4)),
          decoration: _decoracion(e, ejemplo),
        ),
      ],
    );
  }

  Widget _campoNumero(
    Escala e, {
    required String titulo,
    required TextEditingController ctrl,
    required String ejemplo,
    bool entero = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(e, titulo),
        TextField(
          controller: ctrl,
          keyboardType: entero
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          // Números, y en montos también punto y coma
          inputFormatters: [
            entero
                ? FilteringTextInputFormatter.digitsOnly
                : FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4)),
          decoration: _decoracion(
            e,
            ejemplo,
          ).copyWith(prefixText: entero ? null : '\$ '),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _campoFecha(
    Escala e, {
    required String titulo,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(e, titulo),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(e.t(2)),
          child: InputDecorator(
            isEmpty: fecha == null,
            decoration: _decoracion(e, 'Toca para elegir la fecha').copyWith(
              suffixIcon: Icon(
                Icons.calendar_today,
                color: AppTheme.textHint,
                size: e.t(5),
              ),
            ),
            child: Text(
              fecha == null ? '' : _fecha(fecha),
              style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4)),
            ),
          ),
        ),
      ],
    );
  }
}