import 'package:asend/database/birthday_hive_service.dart';
import 'package:asend/models/birthday.dart';

/// Lógica de Cumpleaños. No mueve dinero: es solo un registro.
class BirthdayService {
  // ─────────────────────────────────────────────
  // CÁLCULOS
  // ─────────────────────────────────────────────

  /// Días que faltan para el próximo cumpleaños.
  /// Hoy = 0 (va primero), mañana = 1, ayer = 364 o 365 (va al final).
  static int diasFaltantes(Birthday b) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    // El cumpleaños de este año. Si cae 29/02 en año no bisiesto,
    // Dart lo corre al 01/03 solo, que es un comportamiento aceptable.
    DateTime proximo = DateTime(hoy.year, b.mes, b.dia);

    // Si ya pasó, el próximo es el del año que viene
    if (proximo.isBefore(hoy)) {
      proximo = DateTime(hoy.year + 1, b.mes, b.dia);
    }

    return proximo.difference(hoy).inDays;
  }

  /// Edad que tiene HOY. null si no hay año registrado.
  static int? edadActual(Birthday b) {
    if (b.anio == null) return null;

    final ahora = DateTime.now();
    int edad = ahora.year - b.anio!;

    // Si este año todavía no cumple, resta uno
    final yaCumplio =
        ahora.month > b.mes || (ahora.month == b.mes && ahora.day >= b.dia);
    if (!yaCumplio) edad--;

    return edad < 0 ? 0 : edad;
  }

  /// Edad que tendría hoy alguien nacido en ese año, con esa fecha.
  /// Para mostrarla junto a la rueda de años.
  static int edadParaAnio(int anio, int dia, int mes) {
    final ahora = DateTime.now();
    int edad = ahora.year - anio;

    final yaCumplio =
        ahora.month > mes || (ahora.month == mes && ahora.day >= dia);
    if (!yaCumplio) edad--;

    return edad < 0 ? 0 : edad;
  }

  /// True si el cumpleaños es hoy. Para resaltarlo en la lista.
  static bool esHoy(Birthday b) {
    final ahora = DateTime.now();
    return b.dia == ahora.day && b.mes == ahora.month;
  }

  // ─────────────────────────────────────────────
  // LECTURA
  // ─────────────────────────────────────────────

  /// Ordenados por proximidad: el de hoy primero, el de ayer al final.
  static List<Birthday> getTodos() {
    final cumples = BirthdayHiveService.getBirthdaysBox().values
        .where((b) => b.deletedAt == null)
        .toList();

    cumples.sort((a, b) {
      final comparacion = diasFaltantes(a).compareTo(diasFaltantes(b));
      // Empate el mismo día: alfabético, para que el orden sea estable
      if (comparacion != 0) return comparacion;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });

    return cumples;
  }

  /// Orden alfabético, para los menús de editar y eliminar.
  static List<Birthday> getAlfabetico() {
    final cumples = BirthdayHiveService.getBirthdaysBox().values
        .where((b) => b.deletedAt == null)
        .toList();

    cumples.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );

    return cumples;
  }

  // ─────────────────────────────────────────────
  // ESCRITURA
  // ─────────────────────────────────────────────

  static Future<void> agregar({
    required String nombre,
    required int dia,
    required int mes,
    int? anio,
  }) async {
    final box = BirthdayHiveService.getBirthdaysBox();

    // Buscar el máximo real, nunca values.last.id ni box.length + 1
    int nuevoId = 1;
    for (final b in box.values) {
      if (b.id >= nuevoId) nuevoId = b.id + 1;
    }

    await box.put(
      nuevoId,
      Birthday(
        id: nuevoId,
        nombre: nombre,
        dia: dia,
        mes: mes,
        anio: anio,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Actualiza solo los campos que se pasen. Los que van en null
  /// se dejan como estaban, salvo el año y la nota, que sí se
  /// pueden vaciar con sus banderas.
  static Future<void> editar({
    required int birthdayId,
    String? nombre,
    int? dia,
    int? mes,
    int? anio,
    String? nota,
  }) async {
    final box = BirthdayHiveService.getBirthdaysBox();
    final cumple = box.get(birthdayId);
    if (cumple == null || cumple.deletedAt != null) return;

    if (nombre != null) cumple.nombre = nombre;
    if (dia != null) cumple.dia = dia;
    if (mes != null) cumple.mes = mes;
    if (anio != null) cumple.anio = anio;
    if (nota != null) cumple.nota = nota.isEmpty ? null : nota;

    await box.put(cumple.id, cumple);
  }

  static Future<void> eliminar(int birthdayId) async {
    final box = BirthdayHiveService.getBirthdaysBox();
    final cumple = box.get(birthdayId);
    if (cumple == null || cumple.deletedAt != null) return;

    cumple.deletedAt = DateTime.now();
    await box.put(cumple.id, cumple);
  }
}
