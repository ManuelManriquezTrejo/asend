import 'dart:math';

import 'package:asend/config/app_config.dart';
import 'package:asend/database/gym_hive_service.dart';
import 'package:asend/models/exercise_change.dart';
import 'package:asend/models/gym_day.dart';
import 'package:asend/models/gym_exercise.dart';
import 'package:asend/models/gym_session_log.dart';
import 'package:asend/models/gym_session_set.dart';

class GymService {
  static const List<String> unidadesPeso = ['kg', 'lb'];

  static const int seriesMaximas = 20;
  static const int repsMaximas = 999;
  static const double pesoMaximo = 999;

  // ── Día ────────────────────────────────────────────────

  /// "Hoy" según el corte de las 4 AM: a la 1 AM del 11 sigue
  /// siendo el día 10. Mismo criterio que Rutina y Medidas.
  static DateTime hoy() {
    final ahora = DateTime.now();
    var dia = DateTime(ahora.year, ahora.month, ahora.day);

    if (ahora.hour < AppConfig.dailyCutoffHour) {
      dia = dia.subtract(const Duration(days: 1));
    }
    return dia;
  }

  static bool mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Días de rutina ─────────────────────────────────────

  static List<GymDay> getDias() {
    final dias = GymHiveService.getDaysBox().values
        .where((d) => d.deletedAt == null)
        .toList();

    dias.sort((a, b) => a.orden.compareTo(b.orden));
    return dias;
  }

  /// Un día por id, incluso eliminado: el historial necesita su nombre.
  static GymDay? getDia(int id) {
    try {
      return GymHiveService.getDaysBox().values.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  static bool existeNombreDia(String nombre, {int? exceptoId}) {
    final buscado = nombre.trim().toLowerCase();

    return getDias().any(
      (d) => d.id != exceptoId && d.nombre.trim().toLowerCase() == buscado,
    );
  }

  static Future<GymDay> crearDia(String nombre) async {
    final box = GymHiveService.getDaysBox();

    final nuevoId = box.isEmpty
        ? 1
        : box.values.map((d) => d.id).reduce(max) + 1;

    final activos = getDias();
    final nuevoOrden = activos.isEmpty
        ? 1
        : activos.map((d) => d.orden).reduce(max) + 1;

    final dia = GymDay(
      id: nuevoId,
      nombre: nombre.trim(),
      orden: nuevoOrden,
      createdAt: DateTime.now(),
    );

    await box.put(nuevoId, dia);
    return dia;
  }
    /// Cambia el nombre de un día. Los snapshots del historial
  /// conservan el nombre que tenían, no se tocan.
  static Future<void> renombrarDia(GymDay dia, String nombre) async {
    dia.nombre = nombre.trim();
    await GymHiveService.getDaysBox().put(dia.id, dia);
  }

  /// Deja los días en el orden de la lista que se le pase y
  /// recompacta el campo orden a 1, 2, 3, sin huecos.
  static Future<void> reordenarDias(List<GymDay> dias) async {
    final box = GymHiveService.getDaysBox();

    for (var i = 0; i < dias.length; i++) {
      dias[i].orden = i + 1;
      await box.put(dias[i].id, dias[i]);
    }
  }

  /// Soft delete. Conserva el historial; descarta la sesión en curso.
  static Future<void> eliminarDia(GymDay dia) async {
    await descartarSesion(dia.id);

    for (final ejercicio in getEjercicios(dia.id)) {
      ejercicio.deletedAt = DateTime.now();
      await GymHiveService.getExercisesBox().put(ejercicio.id, ejercicio);
    }

    dia.deletedAt = DateTime.now();
    await GymHiveService.getDaysBox().put(dia.id, dia);
  }

  // ── Ejercicios ─────────────────────────────────────────

  static List<GymExercise> getEjercicios(int diaId) {
    final ejercicios = GymHiveService.getExercisesBox().values
        .where((e) => e.diaId == diaId && e.deletedAt == null)
        .toList();

    ejercicios.sort((a, b) => a.orden.compareTo(b.orden));
    return ejercicios;
  }

  static GymExercise? getEjercicio(int id) {
    try {
      return GymHiveService.getExercisesBox().values.firstWhere(
        (e) => e.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  static bool existeNombreEjercicio(
    int diaId,
    String nombre, {
    int? exceptoId,
  }) {
    final buscado = nombre.trim().toLowerCase();

    return getEjercicios(
      diaId,
    ).any((e) => e.id != exceptoId && e.nombre.trim().toLowerCase() == buscado);
  }

  /// Crea el ejercicio en la posición pedida y recorre los que
  /// estaban de esa posición en adelante. Con [orden] en null va al final.
  static Future<GymExercise> crearEjercicio({
    required int diaId,
    required String nombre,
    required double peso,
    required String unidadPeso,
    required int series,
    required int reps,
    int? orden,
  }) async {
    final box = GymHiveService.getExercisesBox();
    final existentes = getEjercicios(diaId);

    final nuevoId = box.isEmpty
        ? 1
        : box.values.map((e) => e.id).reduce(max) + 1;

    final posicion = orden == null
        ? existentes.length + 1
        : orden.clamp(1, existentes.length + 1);

    // Recorrer los de esa posición en adelante
    for (final e in existentes) {
      if (e.orden >= posicion) {
        e.orden++;
        await box.put(e.id, e);
      }
    }

    final ejercicio = GymExercise(
      id: nuevoId,
      diaId: diaId,
      nombre: nombre.trim(),
      peso: peso,
      unidadPeso: unidadPeso,
      series: series,
      reps: reps,
      orden: posicion,
      createdAt: DateTime.now(),
    );

    await box.put(nuevoId, ejercicio);

    // Crear también su primera entrada de historial, para que la
    // gráfica de peso arranque desde el peso inicial
    await _registrarCambio(ejercicio);

    return ejercicio;
  }

  /// Edita el ejercicio. Si cambió peso, unidad, series o reps,
  /// deja una entrada en el historial de cambios.
  static Future<void> editarEjercicio(
    GymExercise ejercicio, {
    String? nombre,
    double? peso,
    String? unidadPeso,
    int? series,
    int? reps,
    int? orden,
  }) async {
    final box = GymHiveService.getExercisesBox();

    final cambioConfig =
        (peso != null && peso != ejercicio.peso) ||
        (unidadPeso != null && unidadPeso != ejercicio.unidadPeso) ||
        (series != null && series != ejercicio.series) ||
        (reps != null && reps != ejercicio.reps);

    if (nombre != null) ejercicio.nombre = nombre.trim();
    if (peso != null) ejercicio.peso = peso;
    if (unidadPeso != null) ejercicio.unidadPeso = unidadPeso;
    if (series != null) ejercicio.series = series;
    if (reps != null) ejercicio.reps = reps;

    if (orden != null && orden != ejercicio.orden) {
      await _reordenar(ejercicio, orden);
    }

    await box.put(ejercicio.id, ejercicio);

    if (cambioConfig) await _registrarCambio(ejercicio);
  }

  /// Mueve un ejercicio a otra posición y acomoda los demás.
  static Future<void> _reordenar(GymExercise ejercicio, int destino) async {
    final box = GymHiveService.getExercisesBox();
    final lista = getEjercicios(ejercicio.diaId)
      ..removeWhere((e) => e.id == ejercicio.id);

    final posicion = destino.clamp(1, lista.length + 1);
    lista.insert(posicion - 1, ejercicio);

    for (var i = 0; i < lista.length; i++) {
      lista[i].orden = i + 1;
      await box.put(lista[i].id, lista[i]);
    }
  }

  /// Soft delete. Conserva historial y cambios.
  /// Borra sus series de la sesión en curso, si las hay.
  static Future<void> eliminarEjercicio(GymExercise ejercicio) async {
    final sets = GymHiveService.getSetsBox();

    final suyos = sets.values
        .where((s) => s.ejercicioId == ejercicio.id)
        .map((s) => s.id)
        .toList();

    for (final id in suyos) {
      await sets.delete(id);
    }

    ejercicio.deletedAt = DateTime.now();
    await GymHiveService.getExercisesBox().put(ejercicio.id, ejercicio);

    // Recompactar el orden de los que quedan
    final lista = getEjercicios(ejercicio.diaId);
    for (var i = 0; i < lista.length; i++) {
      lista[i].orden = i + 1;
      await GymHiveService.getExercisesBox().put(lista[i].id, lista[i]);
    }
  }

  /// Congela la configuración actual del ejercicio en el historial.
  static Future<void> _registrarCambio(GymExercise ejercicio) async {
    final box = GymHiveService.getChangesBox();

    final nuevoId = box.isEmpty
        ? 1
        : box.values.map((c) => c.id).reduce(max) + 1;

    await box.put(
      nuevoId,
      ExerciseChange(
        id: nuevoId,
        ejercicioId: ejercicio.id,
        peso: ejercicio.peso,
        unidadPeso: ejercicio.unidadPeso,
        series: ejercicio.series,
        reps: ejercicio.reps,
        fecha: hoy(),
        createdAt: DateTime.now(),
      ),
    );
  }

  // ── Sesión en curso ────────────────────────────────────

  static List<GymSessionSet> getSesion(int diaId) {
    return GymHiveService.getSetsBox().values
        .where((s) => s.diaId == diaId)
        .toList();
  }

  /// Un día está en curso cuando ya tiene al menos una rep anotada.
  /// Solo abrirlo no lo inicia.
  static bool estaEnCurso(int diaId) =>
      getSesion(diaId).any((s) => s.reps != null);

  static List<GymDay> getDiasEnCurso() =>
      getDias().where((d) => estaEnCurso(d.id)).toList();

  /// La fecha elegida al abrir un día en curso.
  static DateTime? getFechaSesion(int diaId) {
    final sesion = getSesion(diaId);
    return sesion.isEmpty ? null : sesion.first.fecha;
  }

  /// Las reps anotadas de una serie, o null si está vacía.
  static int? getReps(int diaId, int ejercicioId, int numeroSerie) {
    try {
      return GymHiveService.getSetsBox().values
          .firstWhere(
            (s) =>
                s.diaId == diaId &&
                s.ejercicioId == ejercicioId &&
                s.numeroSerie == numeroSerie,
          )
          .reps;
    } catch (e) {
      return null;
    }
  }

  /// Guarda una casilla al momento de escribirla, para no perder
  /// el progreso si se cierra la app.
  static Future<void> guardarReps({
    required int diaId,
    required int ejercicioId,
    required int numeroSerie,
    required DateTime fecha,
    int? reps,
  }) async {
    final box = GymHiveService.getSetsBox();

    GymSessionSet? existente;
    try {
      existente = box.values.firstWhere(
        (s) =>
            s.diaId == diaId &&
            s.ejercicioId == ejercicioId &&
            s.numeroSerie == numeroSerie,
      );
    } catch (e) {
      existente = null;
    }

    if (existente != null) {
      existente.reps = reps;
      await box.put(existente.id, existente);
      return;
    }

    final nuevoId = box.isEmpty
        ? 1
        : box.values.map((s) => s.id).reduce(max) + 1;

    await box.put(
      nuevoId,
      GymSessionSet(
        id: nuevoId,
        diaId: diaId,
        ejercicioId: ejercicioId,
        numeroSerie: numeroSerie,
        reps: reps,
        fecha: fecha,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Cambia la fecha de toda la sesión en curso.
  static Future<void> cambiarFechaSesion(int diaId, DateTime fecha) async {
    final box = GymHiveService.getSetsBox();

    for (final s in getSesion(diaId)) {
      s.fecha = fecha;
      await box.put(s.id, s);
    }
  }

  /// Borra la sesión en curso sin guardar nada.
  static Future<void> descartarSesion(int diaId) async {
    final box = GymHiveService.getSetsBox();
    final ids = getSesion(diaId).map((s) => s.id).toList();

    for (final id in ids) {
      await box.delete(id);
    }
  }

  // ── Historial ──────────────────────────────────────────

  /// ¿Ya hay un día guardado con esa fecha?
  static bool existeLogEnFecha(int diaId, DateTime fecha) {
    return GymHiveService.getLogsBox().values.any(
      (l) =>
          l.diaId == diaId && l.deletedAt == null && mismoDia(l.fecha, fecha),
    );
  }

  /// Borra del historial un día completo en una fecha.
  static Future<void> eliminarLogEnFecha(int diaId, DateTime fecha) async {
    final box = GymHiveService.getLogsBox();

    final suyos = box.values.where(
      (l) =>
          l.diaId == diaId && l.deletedAt == null && mismoDia(l.fecha, fecha),
    );

    for (final l in suyos) {
      l.deletedAt = DateTime.now();
      await box.put(l.id, l);
    }
  }

  /// Cuántas casillas quedaron sin anotar en la sesión.
  static int contarVacias(int diaId) {
    var vacias = 0;

    for (final ejercicio in getEjercicios(diaId)) {
      for (var serie = 1; serie <= ejercicio.series; serie++) {
        if (getReps(diaId, ejercicio.id, serie) == null) vacias++;
      }
    }
    return vacias;
  }

  /// Pasa la sesión al historial y la borra del día.
  /// Las casillas vacías se guardan como 0.
  static Future<void> finalizarSesion(int diaId) async {
    final fecha = getFechaSesion(diaId) ?? hoy();
    final box = GymHiveService.getLogsBox();

    var nuevoId = box.isEmpty ? 1 : box.values.map((l) => l.id).reduce(max) + 1;

    for (final ejercicio in getEjercicios(diaId)) {
      for (var serie = 1; serie <= ejercicio.series; serie++) {
        await box.put(
          nuevoId,
          GymSessionLog(
            id: nuevoId,
            diaId: diaId,
            ejercicioId: ejercicio.id,
            nombreSnapshot: ejercicio.nombre,
            numeroSerie: serie,
            reps: getReps(diaId, ejercicio.id, serie) ?? 0,
            pesoSnapshot: ejercicio.peso,
            unidadSnapshot: ejercicio.unidadPeso,
            seriesSnapshot: ejercicio.series,
            repsObjetivoSnapshot: ejercicio.reps,
            fecha: fecha,
            createdAt: DateTime.now(),
          ),
        );
        nuevoId++;
      }
    }

    await descartarSesion(diaId);
  }

  /// Cierra las sesiones que quedaron abiertas de días anteriores.
  /// Con al menos una rep anotada van al historial; vacías se descartan.
  /// Se llama al abrir la app y al detectar cambio de día.
  static Future<void> cerrarSesionesViejas() async {
    final hoyDia = hoy();

    for (final dia in getDias()) {
      final fecha = getFechaSesion(dia.id);
      if (fecha == null || !fecha.isBefore(hoyDia)) continue;

      if (estaEnCurso(dia.id)) {
        await finalizarSesion(dia.id);
      } else {
        await descartarSesion(dia.id);
      }
    }
  }

  // ── Validaciones ───────────────────────────────────────

  /// Peso: acepta vacío, 0 y negativos. Vacío y 0 son sin peso extra.
  static String? validarPeso(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;

    final valor = double.tryParse(limpio);
    if (valor == null) return 'Solo números';
    if (valor.abs() > pesoMaximo) return 'Máximo $pesoMaximo';

    return null;
  }

  static double parsearPeso(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    return limpio.isEmpty ? 0 : double.parse(limpio);
  }

  static String? validarSeries(String texto) {
    final valor = int.tryParse(texto.trim());

    if (texto.trim().isEmpty) return 'Escribe las series';
    if (valor == null) return 'Solo números enteros';
    if (valor < 1) return 'Mínimo 1';
    if (valor > seriesMaximas) return 'Máximo $seriesMaximas';

    return null;
  }

  static String? validarReps(String texto) {
    final valor = int.tryParse(texto.trim());

    if (texto.trim().isEmpty) return 'Escribe las reps';
    if (valor == null) return 'Solo números enteros';
    if (valor < 1) return 'Mínimo 1';
    if (valor > repsMaximas) return 'Máximo $repsMaximas';

    return null;
  }

  /// Reps de una casilla de la sesión: aquí sí vale 0.
  static String? validarRepsSesion(String texto) {
    if (texto.trim().isEmpty) return null;

    final valor = int.tryParse(texto.trim());
    if (valor == null) return 'Solo números enteros';
    if (valor < 0) return 'No puede ser negativo';
    if (valor > repsMaximas) return 'Máximo $repsMaximas';

    return null;
  }
}
