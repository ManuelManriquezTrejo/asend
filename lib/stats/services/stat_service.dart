import 'package:asend/database/routine_hive_service.dart';
import 'package:asend/database/stats_hive_service.dart';
import 'package:asend/models/daily_routine_habit.dart';
import 'package:asend/models/magic.dart';
import 'package:asend/models/mission.dart';
import 'package:asend/models/mission_magic_point.dart';
import 'package:asend/models/skill.dart';
import 'package:asend/models/stat.dart';
import 'package:asend/models/stat_link.dart';
import 'package:asend/models/stat_point.dart';
import 'package:asend/routine/services/habit_history_service.dart';
import 'package:asend/stats/data/magic_templates.dart';

/// Lógica del módulo Stats: puntos por día, rangos, rango general,
/// puntos de magia y desbloqueo de habilidades.
class StatService {
  // ── Constantes ─────────────────────────────────────────

  static const List<String> rangos = ['F', 'E', 'D', 'C', 'B', 'A', 'S', 'SS'];

  /// Puntos acumulados para llegar a E, D, C, B, A, S y SS.
  static const List<int> umbralesBase = [10, 30, 70, 150, 300, 600, 1200];

  static const List<String> tiposHabilidad = [
    'Ataque',
    'Defensa',
    'Apoyo',
    'Aumento',
  ];

  static const String barraProgreso = 'progreso';
  static const String barraDatos = 'datos';

  static const String _claveNombre = 'nombrePersonaje';
  static const String _claveUltimoDia = 'ultimoDiaProcesado';

  /// Letra de un rango; −1 (sin rango) se muestra como guion.
  static String letra(int rango) =>
      rango < 0 ? '—' : rangos[rango.clamp(0, rangos.length - 1)];

  // ── Rangos ─────────────────────────────────────────────

  /// Rango (0 = F … 7 = SS) que dan [puntos] con esa tabla.
  static int rangoDe(num puntos, List<num> umbrales) {
    var rango = 0;
    for (final u in umbrales) {
      if (puntos >= u) {
        rango++;
      } else {
        break;
      }
    }
    return rango.clamp(0, rangos.length - 1);
  }

  /// Puntos donde empieza el rango actual (0 para F).
  static num inicioDeRango(int rango, List<num> umbrales) =>
      rango == 0 ? 0 : umbrales[rango - 1];

  /// Puntos que pide el siguiente rango, o null si ya está en SS.
  static num? siguienteUmbral(int rango, List<num> umbrales) =>
      rango < umbrales.length ? umbrales[rango] : null;

  /// Avance de 0 a 1 dentro del rango actual (1 en SS).
  static double avance(num puntos, List<num> umbrales) {
    final rango = rangoDe(puntos, umbrales);
    final siguiente = siguienteUmbral(rango, umbrales);
    if (siguiente == null) return 1;
    final inicio = inicioDeRango(rango, umbrales);
    final tramo = siguiente - inicio;
    if (tramo <= 0) return 1;
    return ((puntos - inicio) / tramo).clamp(0.0, 1.0).toDouble();
  }

  /// Revisa una tabla escrita por el usuario. Devuelve null si está
  /// bien o el mensaje de error.
  static String? validarUmbrales(List<int?> umbrales) {
    if (umbrales.length != umbralesBase.length || umbrales.contains(null)) {
      return 'Escribe los puntos de todos los rangos';
    }
    var anterior = 0;
    for (var i = 0; i < umbrales.length; i++) {
      final u = umbrales[i]!;
      if (u <= anterior) {
        return 'Cada rango debe pedir más puntos que el anterior '
            '(${rangos[i + 1]} pide $u)';
      }
      anterior = u;
    }
    return null;
  }

  // ── Utilidades ─────────────────────────────────────────

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _diaSiguiente(DateTime d) =>
      DateTime(d.year, d.month, d.day + 1);

  /// Siguiente id disponible (máximo real de la caja).
  static int _siguienteId(Iterable<int> ids) {
    var siguiente = 1;
    for (final id in ids) {
      if (id >= siguiente) siguiente = id + 1;
    }
    return siguiente;
  }

  // ── Inicio ─────────────────────────────────────────────

  /// Primera vez: crea Mana, Fuerza, HP y Agilidad, y marca ayer como
  /// último día procesado para que todo empiece desde hoy.
  static Future<void> asegurarInicio() async {
    final box = StatsHiveService.getStatsBox();
    final settings = StatsHiveService.getSettingsBox();

    if (box.isEmpty) {
      final ahora = DateTime.now();
      final nombres = ['Mana', 'Fuerza', 'HP', 'Agilidad'];
      for (var i = 0; i < nombres.length; i++) {
        final stat = Stat(
          id: i + 1,
          nombre: nombres[i],
          esMana: i == 0,
          orden: i,
          umbrales: List<int>.from(umbralesBase),
          createdAt: ahora,
        );
        await box.put(stat.id, stat);
      }
    }

    if (settings.get(_claveUltimoDia) == null) {
      final ayer = HabitHistoryService.getToday().subtract(
        const Duration(days: 1),
      );
      await settings.put(_claveUltimoDia, _dia(ayer).millisecondsSinceEpoch);
    }
  }

  // ── Personaje ──────────────────────────────────────────

  static String nombrePersonaje() =>
      StatsHiveService.getSettingsBox().get(_claveNombre, defaultValue: '')
          as String;

  static Future<void> setNombrePersonaje(String nombre) async {
    await StatsHiveService.getSettingsBox().put(_claveNombre, nombre.trim());
  }

  // ── Estadísticas ───────────────────────────────────────

  /// Estadísticas activas en su orden.
  static List<Stat> getStats() {
    final lista = StatsHiveService.getStatsBox().values
        .where((s) => s.deletedAt == null)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
    return lista;
  }

  static Stat? getStat(int id) {
    final s = StatsHiveService.getStatsBox().get(id);
    return (s == null || s.deletedAt != null) ? null : s;
  }

  static Stat? getMana() {
    for (final s in getStats()) {
      if (s.esMana) return s;
    }
    return null;
  }

  /// Puntos ganados por una estadística (suma de sus días).
  static int puntos(int statId) {
    var total = 0;
    for (final p in StatsHiveService.getPointsBox().values) {
      if (p.statId == statId && p.deletedAt == null) total += p.puntos;
    }
    return total;
  }

  static int rangoStat(Stat s) => rangoDe(puntos(s.id), s.umbrales);

  static String? _validarNombre(String nombre, {int? excepto}) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe un nombre';
    final repetido = getStats().any(
      (s) => s.id != excepto && s.nombre.toLowerCase() == limpio.toLowerCase(),
    );
    return repetido ? 'Ya existe una estadística con ese nombre' : null;
  }

  /// Crea una estadística al final de la lista. Devuelve null o el error.
  static Future<String?> crearStat(String nombre) async {
    final error = _validarNombre(nombre);
    if (error != null) return error;

    final box = StatsHiveService.getStatsBox();
    final stats = getStats();
    final stat = Stat(
      id: _siguienteId(box.values.map((s) => s.id)),
      nombre: nombre.trim(),
      orden: stats.isEmpty ? 0 : stats.last.orden + 1,
      umbrales: List<int>.from(umbralesBase),
      createdAt: DateTime.now(),
    );
    await box.put(stat.id, stat);
    return null;
  }

  /// Guarda nombre, tabla y opciones de barra. Si algo no es válido no
  /// cambia nada y devuelve el error.
  static Future<String?> guardarStat(
    Stat stat, {
    required String nombre,
    required List<int?> umbrales,
    required bool mostrarBarra,
    required bool mostrarRango,
    required String tipoBarra,
  }) async {
    final error =
        _validarNombre(nombre, excepto: stat.id) ?? validarUmbrales(umbrales);
    if (error != null) return error;

    stat.nombre = nombre.trim();
    stat.umbrales = [for (final u in umbrales) u!];
    stat.mostrarBarra = mostrarBarra;
    stat.mostrarRango = mostrarRango;
    stat.tipoBarra = tipoBarra;
    await StatsHiveService.getStatsBox().put(stat.id, stat);
    return null;
  }


  /// Soft delete. Mana no se puede eliminar. Sus hábitos quedan sin
  /// vincular; sus puntos se conservan en la tabla.
  static Future<String?> eliminarStat(Stat stat) async {
    if (stat.esMana) return 'Mana no se puede eliminar';
    final ahora = DateTime.now();

    for (final link in getLinksDeStat(stat.id)) {
      link.deletedAt = ahora;
      await StatsHiveService.getLinksBox().put(link.id, link);
    }

    stat.deletedAt = ahora;
    await StatsHiveService.getStatsBox().put(stat.id, stat);
    return null;
  }

  // ── Barra de datos ─────────────────────────────────────

  /// Lo que queda en la barra de datos: puntos − gastado.
  static double actualDatos(Stat s) {
    final maximo = puntos(s.id).toDouble();
    return (maximo - s.gastado).clamp(0.0, maximo).toDouble();
  }

  /// Resta (cantidad positiva) o suma (negativa) en la barra de datos,
  /// sin bajar de 0 ni pasar del máximo.
  static Future<void> moverDatos(Stat s, double restar) async {
    final maximo = puntos(s.id).toDouble();
    s.gastado = (s.gastado + restar).clamp(0.0, maximo).toDouble();
    await StatsHiveService.getStatsBox().put(s.id, s);
  }

  static Future<void> llenarDatos(Stat s) async {
    s.gastado = 0;
    await StatsHiveService.getStatsBox().put(s.id, s);
  }

  // ── Vínculos con Rutina ────────────────────────────────

  /// Hábitos activos de Rutina en orden alfabético.
  static List<DailyRoutineHabit> getHabitos() {
    final lista = RoutineHiveService.getDailyRoutineHabitBox().values
        .where((h) => h.deletedAt == null)
        .toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  /// Vínculo activo de un hábito, si tiene.
  static StatLink? getLink(int habitId) {
    for (final l in StatsHiveService.getLinksBox().values) {
      if (l.habitId == habitId && l.deletedAt == null) return l;
    }
    return null;
  }

  static List<StatLink> getLinksDeStat(int statId) => StatsHiveService
      .getLinksBox()
      .values
      .where((l) => l.statId == statId && l.deletedAt == null)
      .toList();

  /// Vincula un hábito, cambia su estadística o su factor, o lo
  /// desvincula con [statId] null. Lo ya ganado no cambia: los días
  /// cerrados ya están guardados y el cambio cuenta desde hoy.
  static Future<String?> vincular({
    required int habitId,
    required int? statId,
    required double factor,
  }) async {
    if (factor < 0) return 'Los puntos no pueden ser negativos';

    final box = StatsHiveService.getLinksBox();
    final actual = getLink(habitId);
    final ahora = DateTime.now();

    if (statId == null) {
      if (actual != null) {
        actual.deletedAt = ahora;
        await box.put(actual.id, actual);
      }
      return null;
    }

    if (actual == null) {
      final link = StatLink(
        id: _siguienteId(box.values.map((l) => l.id)),
        habitId: habitId,
        statId: statId,
        factor: factor,
        fechaVinculo: HabitHistoryService.getToday(),
      );
      await box.put(link.id, link);
      return null;
    }

    if (actual.statId != statId || actual.factor != factor) {
      actual.statId = statId;
      actual.factor = factor;
      actual.fechaCambio = ahora;
      await box.put(actual.id, actual);
    }
    return null;
  }

  /// Texto corto del valor: "1 pt por hora" o "1 pt por nota 10".
  static String textoFactor(DailyRoutineHabit h, double factor) {
    final unidad = h.tipo == 'hora' ? 'por hora' : 'por nota 10';
    return '${numero(factor)} pt $unidad';
  }

  /// Número sin ceros de sobra: 1, 1.5, 0.25.
  static String numero(num valor) {
    if (valor == valor.roundToDouble()) return valor.toInt().toString();
    return valor
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  // ── Puntos por día ─────────────────────────────────────

  /// Procesa cada día cerrado desde el último procesado hasta ayer:
  /// suma por estadística los puntos de sus hábitos y guarda la parte
  /// entera. Se llama junto con el auto-relleno de Rutina, al abrir la
  /// app y al cambiar de día, aunque Stats esté apagado. Si ya está
  /// corriendo, se espera a esa misma vuelta para no contar dos veces.
  static Future<void> procesarDiasCerrados() =>
      _enCurso ??= _procesarPendientes().whenComplete(() => _enCurso = null);

  static Future<void>? _enCurso;

  static Future<void> _procesarPendientes() async {
    final settings = StatsHiveService.getSettingsBox();
    final guardado = settings.get(_claveUltimoDia) as int?;
    final hoy = HabitHistoryService.getToday();

    if (guardado == null) {
      await asegurarInicio();
      return;
    }

    var dia = _diaSiguiente(DateTime.fromMillisecondsSinceEpoch(guardado));
    while (dia.isBefore(hoy)) {
      await _procesarDia(dia);
      await settings.put(_claveUltimoDia, dia.millisecondsSinceEpoch);
      dia = _diaSiguiente(dia);
    }
  }

  static Future<void> _procesarDia(DateTime dia) async {
    final historial = RoutineHiveService.getHabitHistoryBox().values.where(
      (r) => r.deletedAt == null && r.recordDate.isAtSameMomentAs(dia),
    );

    // Suma con decimales por estadística
    final sumas = <int, double>{};
    for (final r in historial) {
      final link = getLink(r.habitId);
      if (link == null) continue;
      if (link.fechaVinculo.isAfter(dia)) continue;
      if (getStat(link.statId) == null) continue;

      // Hora: horas × factor. Nota: (nota / 10) × factor, así 11 da 1.1
      final base = r.tipoSnapshot == 'hora' ? r.value : r.value / 10;
      sumas[link.statId] = (sumas[link.statId] ?? 0) + base * link.factor;
    }

    final box = StatsHiveService.getPointsBox();
    var siguiente = _siguienteId(box.values.map((p) => p.id));
    final ahora = DateTime.now();

    for (final entrada in sumas.entries) {
      // Los decimales sobrantes se pierden; el margen evita que 2.9999
      // por redondeo quede en 2
      final enteros = (entrada.value + 1e-9).floor();
      if (enteros <= 0) continue;

      final punto = StatPoint(
        id: siguiente,
        statId: entrada.key,
        fecha: dia,
        puntos: enteros,
        createdAt: ahora,
      );
      await box.put(punto.id, punto);
      siguiente++;
    }
  }

  // ── Magias ─────────────────────────────────────────────

  static List<Magic> getMagias() {
    final lista = StatsHiveService.getMagicsBox().values
        .where((m) => m.deletedAt == null)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
    return lista;
  }

  static Magic? getMagia(int id) {
    final m = StatsHiveService.getMagicsBox().get(id);
    return (m == null || m.deletedAt != null) ? null : m;
  }

  static int rangoMagia(Magic m) => rangoDe(m.puntos, m.umbrales);

  /// Puntos de magia que vienen de Mana: cada punto que gana Mana es
  /// también un punto de magia.
  static int puntosMagiaDeMana() {
    final mana = getMana();
    return mana == null ? 0 : puntos(mana.id);
  }

  /// Puntos de magia ganados al completar misiones.
  static int puntosMagiaDeMisiones() {
    var total = 0;
    for (final p in StatsHiveService.getMissionPointsBox().values) {
      if (p.deletedAt == null) total += p.puntos;
    }
    return total;
  }

  /// Todos los puntos de magia ganados: Mana más misiones.
  static int puntosMagiaTotales() =>
      puntosMagiaDeMana() + puntosMagiaDeMisiones();

  /// Puntos de magia que aún no están en ninguna magia.
  static int puntosMagiaDisponibles() {
    var asignados = 0;
    for (final m in getMagias()) {
      asignados += m.puntos;
    }
    return puntosMagiaTotales() - asignados;
  }

  /// Plantillas de fábrica que todavía no están agregadas.
  static List<PlantillaMagia> plantillasDisponibles() {
    final usadas = getMagias().map((m) => m.plantilla).toSet();
    return plantillasMagia.where((p) => !usadas.contains(p.clave)).toList();
  }

  /// Agrega magias de fábrica con todas sus habilidades.
  static Future<void> agregarPlantillas(List<PlantillaMagia> elegidas) async {
    final box = StatsHiveService.getMagicsBox();
    final ahora = DateTime.now();

    for (final p in elegidas) {
      final magias = getMagias();
      final magia = Magic(
        id: _siguienteId(box.values.map((m) => m.id)),
        nombre: p.nombre,
        plantilla: p.clave,
        umbrales: List<int>.from(umbralesBase),
        orden: magias.isEmpty ? 0 : magias.last.orden + 1,
        createdAt: ahora,
      );
      await box.put(magia.id, magia);
      await _copiarHabilidades(p, magia.id);
    }
  }

  /// Copia a una magia todas las habilidades de su plantilla.
  static Future<void> _copiarHabilidades(PlantillaMagia p, int magicId) async {
    final skills = StatsHiveService.getSkillsBox();
    final ahora = DateTime.now();

    var orden = 0;
    for (final h in p.habilidades) {
      final skill = Skill(
        id: _siguienteId(skills.values.map((s) => s.id)),
        nombre: h.nombre,
        magicId: magicId,
        tipo: h.tipo,
        nota: h.nota,
        niveles: [
          for (final n in h.niveles)
            SkillLevel(
              rango: n.rango,
              descripcion: n.descripcion,
              mana: n.mana,
            ),
        ],
        orden: orden,
        createdAt: ahora,
      );
      await skills.put(skill.id, skill);
      orden++;
    }
  }

  /// Plantilla de la que salió una magia, o null si se creó desde cero.
  static PlantillaMagia? plantillaDe(Magic magia) {
    for (final p in plantillasMagia) {
      if (p.clave == magia.plantilla) return p;
    }
    return null;
  }

  /// Reemplaza las habilidades de una magia de fábrica por las de su
  /// plantilla actual (descripciones y costos de mana al día). Los
  /// puntos y el rango de la magia no cambian.
  static Future<void> restaurarHabilidades(Magic magia) async {
    final plantilla = plantillaDe(magia);
    if (plantilla == null) return;

    final ahora = DateTime.now();
    for (final s in getHabilidades().where((s) => s.magicId == magia.id)) {
      s.deletedAt = ahora;
      await StatsHiveService.getSkillsBox().put(s.id, s);
    }
    await _copiarHabilidades(plantilla, magia.id);
  }

  static String? _validarNombreMagia(String nombre, {int? excepto}) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe un nombre';
    final repetido = getMagias().any(
      (m) => m.id != excepto && m.nombre.toLowerCase() == limpio.toLowerCase(),
    );
    return repetido ? 'Ya existe una magia con ese nombre' : null;
  }

  /// Crea una magia nueva sin habilidades. Devuelve null o el error.
  static Future<String?> crearMagia(String nombre) async {
    final error = _validarNombreMagia(nombre);
    if (error != null) return error;

    final box = StatsHiveService.getMagicsBox();
    final magias = getMagias();
    final magia = Magic(
      id: _siguienteId(box.values.map((m) => m.id)),
      nombre: nombre.trim(),
      umbrales: List<int>.from(umbralesBase),
      orden: magias.isEmpty ? 0 : magias.last.orden + 1,
      createdAt: DateTime.now(),
    );
    await box.put(magia.id, magia);
    return null;
  }

  /// Guarda nombre y tabla. Si algo no es válido no cambia nada y
  /// devuelve el error.
  static Future<String?> guardarMagia(
    Magic magia, {
    required String nombre,
    required List<int?> umbrales,
  }) async {
    final error =
        _validarNombreMagia(nombre, excepto: magia.id) ??
        validarUmbrales(umbrales);
    if (error != null) return error;

    magia.nombre = nombre.trim();
    magia.umbrales = [for (final u in umbrales) u!];
    await StatsHiveService.getMagicsBox().put(magia.id, magia);
    return null;
  }

  /// Suma (positivo) o quita (negativo) puntos a una magia. Devuelve
  /// null o el error si no alcanzan.
  static Future<String?> asignarPuntos(Magic magia, int cantidad) async {
    if (cantidad > 0 && cantidad > puntosMagiaDisponibles()) {
      return 'Solo hay ${puntosMagiaDisponibles()} puntos disponibles';
    }
    if (cantidad < 0 && -cantidad > magia.puntos) {
      return '${magia.nombre} solo tiene ${magia.puntos} puntos';
    }
    magia.puntos += cantidad;
    await StatsHiveService.getMagicsBox().put(magia.id, magia);
    return null;
  }

  /// Soft delete de la magia y sus habilidades. Sus puntos regresan a
  /// disponibles.
  static Future<void> eliminarMagia(Magic magia) async {
    final ahora = DateTime.now();
    for (final s in getHabilidades().where((s) => s.magicId == magia.id)) {
      s.deletedAt = ahora;
      await StatsHiveService.getSkillsBox().put(s.id, s);
    }
    magia.deletedAt = ahora;
    await StatsHiveService.getMagicsBox().put(magia.id, magia);
  }

  // ── Misiones ───────────────────────────────────────────

  /// Puntos de magia que dará una misión al completarse (0 si no se
  /// configuró).
  static int puntosDeMision(int missionId) =>
      StatsHiveService.getMissionRewardsBox().get(missionId, defaultValue: 0)
          as int;

  /// Cambia los puntos de magia de una misión. Devuelve null o el error.
  static Future<String?> setPuntosDeMision(int missionId, int puntos) async {
    if (puntos < 0) return 'Los puntos no pueden ser negativos';
    final box = StatsHiveService.getMissionRewardsBox();
    if (puntos == 0) {
      await box.delete(missionId);
    } else {
      await box.put(missionId, puntos);
    }
    return null;
  }

  /// Al completar una misión: si da puntos de magia, se suman en ese
  /// momento a los disponibles. Corre aunque Stats esté apagado.
  static Future<void> premiarMision(Mission mision) async {
    final puntos = puntosDeMision(mision.id);
    if (puntos <= 0) return;

    final box = StatsHiveService.getMissionPointsBox();
    final registro = MissionMagicPoint(
      id: _siguienteId(box.values.map((p) => p.id)),
      missionId: mision.id,
      nombre: mision.nombre,
      puntos: puntos,
      fecha: DateTime.now(),
    );
    await box.put(registro.id, registro);
  }

  /// Misiones completadas que dieron puntos, la más reciente primero.
  static List<MissionMagicPoint> getPuntosDeMisiones() {
    final lista = StatsHiveService.getMissionPointsBox().values
        .where((p) => p.deletedAt == null)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  // ── Rango general ──────────────────────────────────────

  /// Tablas de todas las estadísticas y magias activas.
  static List<List<int>> _tablas() => [
    for (final s in getStats()) s.umbrales,
    for (final m in getMagias()) m.umbrales,
  ];

  /// Tabla del rango general: para cada letra, el promedio de lo que
  /// pide esa letra en cada estadística y magia.
  static List<double> tablaGeneral() {
    final tablas = _tablas();
    if (tablas.isEmpty) return umbralesBase.map((u) => u.toDouble()).toList();

    return List.generate(umbralesBase.length, (i) {
      var suma = 0;
      for (final t in tablas) {
        suma += t[i];
      }
      return suma / tablas.length;
    });
  }

  /// Promedio de los puntos de todas las estadísticas y magias.
  static double puntosGeneral() {
    final stats = getStats();
    final magias = getMagias();
    final cuantos = stats.length + magias.length;
    if (cuantos == 0) return 0;

    var suma = 0;
    for (final s in stats) {
      suma += puntos(s.id);
    }
    for (final m in magias) {
      suma += m.puntos;
    }
    return suma / cuantos;
  }

  static int rangoGeneral() => rangoDe(puntosGeneral(), tablaGeneral());

  // ── Habilidades ────────────────────────────────────────

  static List<Skill> getHabilidades() {
    final lista = StatsHiveService.getSkillsBox().values
        .where((s) => s.deletedAt == null)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
    return lista;
  }

  /// Rango con el que se comparan sus niveles: el de su magia o, si es
  /// de magia única, el general.
  static int rangoParaHabilidad(Skill s) {
    if (s.magicId == null) return rangoGeneral();
    final magia = getMagia(s.magicId!);
    return magia == null ? -1 : rangoMagia(magia);
  }

  static bool nivelObtenido(SkillLevel nivel, int rangoActual) =>
      nivel.rango < 0 || nivel.rango <= rangoActual;

  /// Crea o reemplaza una habilidad. Devuelve null o el error.
  static Future<String?> guardarHabilidad(Skill skill) async {
    if (skill.nombre.trim().isEmpty) return 'Escribe un nombre';
    if (skill.niveles.isEmpty) return 'Agrega al menos un nivel';
    for (final n in skill.niveles) {
      if (n.descripcion.trim().isEmpty) {
        return 'Cada nivel necesita su descripción';
      }
    }
    final rangosUsados = skill.niveles.map((n) => n.rango).toList();
    if (rangosUsados.toSet().length != rangosUsados.length) {
      return 'Hay dos niveles con el mismo rango';
    }

    skill.nombre = skill.nombre.trim();
    skill.niveles.sort((a, b) => a.rango.compareTo(b.rango));
    await StatsHiveService.getSkillsBox().put(skill.id, skill);
    return null;
  }

  /// Habilidad nueva vacía, lista para llenar en su pantalla.
  static Skill nuevaHabilidad({int? magicId}) {
    final box = StatsHiveService.getSkillsBox();
    final todas = getHabilidades();
    return Skill(
      id: _siguienteId(box.values.map((s) => s.id)),
      nombre: '',
      magicId: magicId,
      tipo: tiposHabilidad.first,
      niveles: [SkillLevel(rango: magicId == null ? -1 : 0, descripcion: '')],
      orden: todas.isEmpty ? 0 : todas.last.orden + 1,
      createdAt: DateTime.now(),
    );
  }

  static Future<void> eliminarHabilidad(Skill skill) async {
    skill.deletedAt = DateTime.now();
    await StatsHiveService.getSkillsBox().put(skill.id, skill);
  }
}
