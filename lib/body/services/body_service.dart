import 'dart:math';

import 'package:asend/config/app_config.dart';
import 'package:asend/database/body_hive_service.dart';
import 'package:asend/models/body_measurement.dart';
import 'package:asend/models/body_zone.dart';

class BodyService {
  /// Unidades disponibles al crear o editar una zona.
  static const List<String> unidades = ['cm', 'mm', 'in', 'kg', 'lb', '%'];

  /// Valor máximo permitido en una medición.
  static const double valorMaximo = 999;

  // ── Día ────────────────────────────────────────────────

  /// "Hoy" según el corte de las 4 AM: antes del corte cuenta como ayer.
  /// Mismo criterio que Rutina, para que toda la app hable del mismo día.
  static DateTime hoy() {
    final ahora = DateTime.now();
    var dia = DateTime(ahora.year, ahora.month, ahora.day);

    if (ahora.hour < AppConfig.dailyCutoffHour) {
      dia = dia.subtract(const Duration(days: 1));
    }
    return dia;
  }

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Zonas ──────────────────────────────────────────────

  /// Zonas activas, en su orden.
  static List<BodyZone> getZonas() {
    final zonas = BodyHiveService.getZonesBox().values
        .where((z) => z.deletedAt == null)
        .toList();

    zonas.sort((a, b) => a.orden.compareTo(b.orden));
    return zonas;
  }

  /// Una zona por id, incluso si está eliminada.
  /// Las mediciones viejas necesitan su nombre para mostrarse.
  static BodyZone? getZona(int id) {
    try {
      return BodyHiveService.getZonesBox().values.firstWhere((z) => z.id == id);
    } catch (e) {
      return null;
    }
  }

  /// ¿Ya existe una zona activa con ese nombre?
  /// Ignora mayúsculas y espacios sobrantes.
  static bool existeNombreZona(String nombre, {int? exceptoId}) {
    final buscado = nombre.trim().toLowerCase();

    return getZonas().any(
      (z) => z.id != exceptoId && z.nombre.trim().toLowerCase() == buscado,
    );
  }

  static Future<BodyZone> crearZona({
    required String nombre,
    required String unidad,
  }) async {
    final box = BodyHiveService.getZonesBox();

    // ID por el máximo real, no por la cantidad de registros
    final nuevoId = box.isEmpty
        ? 1
        : box.values.map((z) => z.id).reduce(max) + 1;

    // Orden: al final de la lista
    final activas = getZonas();
    final nuevoOrden = activas.isEmpty
        ? 1
        : activas.map((z) => z.orden).reduce(max) + 1;

    final zona = BodyZone(
      id: nuevoId,
      nombre: nombre.trim(),
      unidad: unidad,
      orden: nuevoOrden,
      createdAt: DateTime.now(),
    );

    await box.put(nuevoId, zona);
    return zona;
  }

  /// Cambia nombre o unidad. Las mediciones ya hechas conservan
  /// la unidad que tenían, gracias a unidadSnapshot.
  static Future<void> editarZona(
    BodyZone zona, {
    String? nombre,
    String? unidad,
  }) async {
    if (nombre != null) zona.nombre = nombre.trim();
    if (unidad != null) zona.unidad = unidad;

    await BodyHiveService.getZonesBox().put(zona.id, zona);
  }

  /// Soft delete: la zona desaparece de la lista pero sus mediciones
  /// se conservan para las gráficas.
  static Future<void> eliminarZona(BodyZone zona) async {
    zona.deletedAt = DateTime.now();
    await BodyHiveService.getZonesBox().put(zona.id, zona);
  }

  // ── Mediciones ─────────────────────────────────────────

  /// Mediciones activas de una zona, de la más reciente a la más vieja.
  static List<BodyMeasurement> getMedicionesDeZona(int zonaId) {
    final medidas = BodyHiveService.getMeasurementsBox().values
        .where((m) => m.zonaId == zonaId && m.deletedAt == null)
        .toList();

    medidas.sort((a, b) => b.fecha.compareTo(a.fecha));
    return medidas;
  }

  /// La medición más reciente de una zona, o null si nunca se midió.
  static BodyMeasurement? getUltimaMedicion(int zonaId) {
    final medidas = getMedicionesDeZona(zonaId);
    return medidas.isEmpty ? null : medidas.first;
  }

  /// La medición de hoy de una zona, si existe.
  static BodyMeasurement? getMedicionDeHoy(int zonaId) {
    final dia = hoy();

    try {
      return BodyHiveService.getMeasurementsBox().values.firstWhere(
        (m) =>
            m.zonaId == zonaId &&
            m.deletedAt == null &&
            _mismoDia(m.fecha, dia),
      );
    } catch (e) {
      return null;
    }
  }

  /// Zonas que aún no tienen medición de hoy.
  /// Es lo que recorre la pantalla de agregar medidas.
  static List<BodyZone> getZonasPendientesHoy() {
    return getZonas().where((z) => getMedicionDeHoy(z.id) == null).toList();
  }

  /// ¿Todas las zonas activas ya tienen medición de hoy?
  /// Sin zonas, devuelve false: no hay nada que medir todavía.
  static bool yaMidioTodoHoy() {
    final zonas = getZonas();
    return zonas.isNotEmpty && getZonasPendientesHoy().isEmpty;
  }

  /// Guarda el valor de hoy de una zona.
  /// Si ya había uno de hoy, lo sobrescribe (corrección).
  static Future<void> guardarMedicion({
    required BodyZone zona,
    required double valor,
  }) async {
    final box = BodyHiveService.getMeasurementsBox();
    final existente = getMedicionDeHoy(zona.id);

    if (existente != null) {
      existente.valor = valor;
      existente.unidadSnapshot = zona.unidad;
      await box.put(existente.id, existente);
      return;
    }

    final nuevoId = box.isEmpty
        ? 1
        : box.values.map((m) => m.id).reduce(max) + 1;

    final medicion = BodyMeasurement(
      id: nuevoId,
      zonaId: zona.id,
      valor: valor,
      unidadSnapshot: zona.unidad,
      fecha: hoy(),
      createdAt: DateTime.now(),
    );

    await box.put(nuevoId, medicion);
  }

  /// Valida lo que el usuario escribió.
  /// Devuelve el error a mostrar, o null si el valor sirve.
  static String? validarValor(String texto) {
    // Algunos teclados de Android dan coma en lugar de punto
    final limpio = texto.trim().replaceAll(',', '.');

    if (limpio.isEmpty) return 'Escribe un valor';

    final valor = double.tryParse(limpio);
    if (valor == null) return 'Solo números';
    if (valor <= 0) return 'Debe ser mayor que 0';
    if (valor > valorMaximo) return 'Máximo $valorMaximo';

    return null;
  }

  /// Convierte el texto ya validado a número.
  static double parsearValor(String texto) =>
      double.parse(texto.trim().replaceAll(',', '.'));
}
