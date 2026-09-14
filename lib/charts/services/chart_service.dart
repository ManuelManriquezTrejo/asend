import 'dart:math';

import 'package:asend/body/services/body_service.dart';
import 'package:asend/database/cash_out_hive_service.dart';
import 'package:asend/database/chart_hive_service.dart';
import 'package:asend/database/gym_hive_service.dart';
import 'package:asend/database/routine_hive_service.dart';
import 'package:asend/gym/services/gym_service.dart';
import 'package:asend/models/chart_line_color.dart';
import 'package:flutter/material.dart';

/// Un punto de una línea: el día y su valor.
class ChartPoint {
  final DateTime fecha;
  final double valor;

  const ChartPoint(this.fecha, this.valor);
}

/// Una línea completa de la gráfica, con su nombre y sus puntos.
/// La clave identifica la línea entre módulos para guardarle el color.
class ChartLine {
  final String clave;
  final String nombre;
  final List<ChartPoint> puntos;

  const ChartLine({
    required this.clave,
    required this.nombre,
    required this.puntos,
  });
}

/// Qué se puede graficar. Gym y Rutina se dividen en dos cada uno.
enum ChartScope { gymPeso, gymReps, medidas, pagos, rutinaHora, rutinaNota }

class ChartService {
  /// Colores que se reparten en orden a las líneas sin color propio.
  static const List<Color> coloresPorDefecto = [
    Color(0xFF4CAF50), // Verde
    Color(0xFF8BC34A), // Verde pasto
    Color(0xFFF44336), // Rojo
    Color(0xFFFFEB3B), // Amarillo
    Color(0xFF2196F3), // Azul
    Color(0xFFFF9800), // Naranja
    Color(0xFF9C27B0), // Morado
    Color(0xFF00BCD4), // Cian
    Color(0xFFE91E63), // Rosa
    Color(0xFF795548), // Café
    Color(0xFF607D8B), // Gris azulado
    Color(0xFFCDDC39), // Lima
  ];

  // ── Lectura por ámbito ─────────────────────────────────

  /// Las líneas de un ámbito, ya listas para graficar.
  /// Cada línea trae sus puntos ordenados del día más viejo al más nuevo.
  static List<ChartLine> getLineas(ChartScope ambito) {
    switch (ambito) {
      case ChartScope.gymPeso:
        return _gymPeso();
      case ChartScope.gymReps:
        return _gymReps();
      case ChartScope.medidas:
        return _medidas();
      case ChartScope.pagos:
        return _pagos();
      case ChartScope.rutinaHora:
        return _rutina('hora');
      case ChartScope.rutinaNota:
        return _rutina('nota');
    }
  }

  /// Peso de cada ejercicio en el tiempo, una línea por ejercicio.
  /// Sale de ExerciseChange, que guarda una entrada cada vez que
  /// cambia la configuración del ejercicio.
  static List<ChartLine> _gymPeso() {
    final lineas = <ChartLine>[];

    for (final dia in GymService.getDias()) {
      for (final ejercicio in GymService.getEjercicios(dia.id)) {
        final cambios = GymHiveService.getChangesBox().values
            .where((c) => c.ejercicioId == ejercicio.id)
            .toList()
          ..sort((a, b) => a.fecha.compareTo(b.fecha));

        if (cambios.isEmpty) continue;

        lineas.add(
          ChartLine(
            clave: 'gym_peso:${ejercicio.id}',
            nombre: '${ejercicio.nombre} (${dia.nombre})',
            puntos: cambios
                .map((c) => ChartPoint(_soloFecha(c.fecha), c.peso))
                .toList(),
          ),
        );
      }
    }

    return lineas;
  }

  /// Promedio de reps por día de cada ejercicio, una línea por ejercicio.
  /// Las series en 0 cuentan: un día incompleto debe verse más bajo.
  static List<ChartLine> _gymReps() {
    final lineas = <ChartLine>[];
    final logs = GymHiveService.getLogsBox().values
        .where((l) => l.deletedAt == null)
        .toList();

    // Agrupar por ejercicio y luego por día
    final porEjercicio = <int, Map<DateTime, List<int>>>{};

    for (final log in logs) {
      final dia = _soloFecha(log.fecha);
      // Una serie sin anotar vale 0: un día incompleto debe verse más bajo
      porEjercicio
          .putIfAbsent(log.ejercicioId, () => {})
          .putIfAbsent(dia, () => [])
          .add(log.reps ?? 0);
    }

    for (final entrada in porEjercicio.entries) {
      final ejercicio = GymService.getEjercicio(entrada.key);
      if (ejercicio == null) continue;

      final dias = entrada.value.keys.toList()..sort();

      lineas.add(
        ChartLine(
          clave: 'gym_reps:${entrada.key}',
          nombre: ejercicio.nombre,
          puntos: dias.map((d) {
            final reps = entrada.value[d]!;
            final suma = reps.fold<int>(0, (a, b) => a + b);
            return ChartPoint(d, suma / reps.length);
          }).toList(),
        ),
      );
    }

    return lineas;
  }

  /// Valor de cada zona del cuerpo en el tiempo, una línea por zona.
  /// Todas comparten escala a propósito: kg, cm y % van juntos.
  static List<ChartLine> _medidas() {
    final lineas = <ChartLine>[];

    for (final zona in BodyService.getZonas()) {
      final medidas = BodyService.getMedicionesDeZona(zona.id).toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));

      if (medidas.isEmpty) continue;

      lineas.add(
        ChartLine(
          clave: 'medidas:${zona.id}',
          nombre: zona.nombre,
          puntos: medidas
              .map((m) => ChartPoint(_soloFecha(m.fecha), m.valor))
              .toList(),
        ),
      );
    }

    return lineas;
  }

  /// Lo cobrado cada día. Una sola línea, sumando todos los pagos del día.
  static List<ChartLine> _pagos() {
    final pagados = CashOutHiveService.getCashOutBox().values
        .where((p) => p.deletedAt == null && p.pagado)
        .toList();

    if (pagados.isEmpty) return [];

    final porDia = <DateTime, double>{};
    for (final p in pagados) {
      final dia = _soloFecha(p.fecha);
      porDia[dia] = (porDia[dia] ?? 0) + p.cantidad;
    }

    final dias = porDia.keys.toList()..sort();

    return [
      ChartLine(
        clave: 'pagos',
        nombre: 'Pagos cobrados',
        puntos: dias.map((d) => ChartPoint(d, porDia[d]!)).toList(),
      ),
    ];
  }

  /// Valor registrado cada día, una línea por hábito.
  /// [tipo] separa los de hora de los de nota, que no comparten escala.
  static List<ChartLine> _rutina(String tipo) {
    final lineas = <ChartLine>[];
    final habits = RoutineHiveService.getDailyRoutineHabitBox().values
        .where((h) => h.deletedAt == null && h.tipo == tipo)
        .toList()
      ..sort((a, b) => a.prioridad.compareTo(b.prioridad));

    final historial = RoutineHiveService.getHabitHistoryBox().values
        .where((r) => r.deletedAt == null)
        .toList();

    for (final habit in habits) {
      final registros = historial
          .where((r) => r.habitId == habit.id && r.tipoSnapshot == tipo)
          .toList()
        ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

      if (registros.isEmpty) continue;

      lineas.add(
        ChartLine(
          clave: 'rutina:${habit.id}',
          nombre: habit.nombre,
          puntos: registros
              .map((r) => ChartPoint(_soloFecha(r.recordDate), r.value))
              .toList(),
        ),
      );
    }

    return lineas;
  }

  // ── Rango de fechas ────────────────────────────────────

  /// El primer y el último día con datos entre todas las líneas.
  /// Es el rango que abarca la gráfica cuando está totalmente alejada.
  /// Sin datos devuelve null.
  static DateTimeRange? getRango(List<ChartLine> lineas) {
    DateTime? primero;
    DateTime? ultimo;

    for (final linea in lineas) {
      for (final punto in linea.puntos) {
        if (primero == null || punto.fecha.isBefore(primero)) {
          primero = punto.fecha;
        }
        if (ultimo == null || punto.fecha.isAfter(ultimo)) {
          ultimo = punto.fecha;
        }
      }
    }

    if (primero == null || ultimo == null) return null;
    return DateTimeRange(start: primero, end: ultimo);
  }

  // ── Colores ────────────────────────────────────────────

  /// El color de una línea: el que el usuario guardó, o el que le
  /// toca por su posición en la lista.
  static Color getColor(String clave, int posicion) {
    final guardado = _buscarColor(clave);

    if (guardado != null) return Color(guardado.color);

    return coloresPorDefecto[posicion % coloresPorDefecto.length];
  }

  /// Guarda el color elegido para una línea, o lo actualiza si ya tenía.
  static Future<void> setColor(String clave, Color color) async {
    final box = ChartHiveService.getLineColorsBox();
    final existente = _buscarColor(clave);

    final valor = color.toARGB32();

    if (existente != null) {
      existente.color = valor;
      await box.put(existente.id, existente);
      return;
    }

    final nuevoId = box.isEmpty
        ? 1
        : box.values.map((c) => c.id).reduce(max) + 1;

    await box.put(
      nuevoId,
      ChartLineColor(
        id: nuevoId,
        clave: clave,
        color: valor,
        createdAt: DateTime.now(),
      ),
    );
  }

  static ChartLineColor? _buscarColor(String clave) {
    try {
      return ChartHiveService.getLineColorsBox().values.firstWhere(
        (c) => c.clave == clave && c.deletedAt == null,
      );
    } catch (e) {
      return null;
    }
  }

  // ── Utilidades ─────────────────────────────────────────

  /// Corta la hora para que dos registros del mismo día caigan
  /// exactamente en el mismo punto del eje X.
  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);
}