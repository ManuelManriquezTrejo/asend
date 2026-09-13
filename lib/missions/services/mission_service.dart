import 'package:asend/models/mission.dart';
import 'package:asend/models/mission_history.dart';
import 'package:asend/database/mission_hive_service.dart';
import 'package:asend/cashout/services/cash_out_service.dart';

class MissionService {
  /// Misiones principales activas, ordenadas por fechaInicio.
  /// Las que no tienen fecha van al final.
  static List<Mission> getPrincipales() {
    final box = MissionHiveService.getMissionBox();
    final list = box.values
        .where((m) => m.deletedAt == null && m.parentId == null)
        .toList();

    list.sort((a, b) {
      if (a.fechaInicio == null && b.fechaInicio == null) {
        return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      }
      if (a.fechaInicio == null) return 1; // sin fecha al final
      if (b.fechaInicio == null) return -1;
      return a.fechaInicio!.compareTo(b.fechaInicio!);
    });

    return list;
  }

  /// Submisiones activas de una misión, ordenadas por fechaInicio
  static List<Mission> getSubmisiones(int parentId) {
    final box = MissionHiveService.getMissionBox();
    final list = box.values
        .where((m) => m.deletedAt == null && m.parentId == parentId)
        .toList();

    list.sort((a, b) {
      if (a.fechaInicio == null && b.fechaInicio == null) {
        return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      }
      if (a.fechaInicio == null) return 1;
      if (b.fechaInicio == null) return -1;
      return a.fechaInicio!.compareTo(b.fechaInicio!);
    });

    return list;
  }

  /// Siguiente id disponible (busca el máximo real, no el último insertado)
  static int _nextMissionId() {
    final box = MissionHiveService.getMissionBox();
    int next = 1;
    for (final m in box.values) {
      if (m.id >= next) next = m.id + 1;
    }
    return next;
  }

  /// Crear misión. parentId null = principal; con valor = solo principales.
  static Future<Mission> createMission({
    required String nombre,
    int? parentId,
    double valor = 0.0,
    DateTime? fechaInicio,
    DateTime? fechaLimite,
  }) async {
    final box = MissionHiveService.getMissionBox();

    final mission = Mission(
      id: _nextMissionId(),
      parentId: parentId,
      nombre: nombre,
      valor: parentId == null ? valor : 0.0, // las hijas nunca pagan
      fechaInicio: fechaInicio,
      fechaLimite: fechaLimite,
      createdAt: DateTime.now(),
    );

    await box.add(mission);
    print('✅ Misión creada: ${mission.nombre} (id ${mission.id})');
    return mission;
  }

  /// Guardar cambios usando la clave real de Hive
  static Future<void> saveMission(Mission mission) async {
    final box = MissionHiveService.getMissionBox();
    for (final k in box.keys) {
      if (box.get(k)?.id == mission.id) {
        await box.put(k, mission);
        return;
      }
    }
  }

  /// Marcar/desmarcar el check visual de una submisión
  static Future<void> toggleSubmision(Mission sub) async {
    sub.completed = !sub.completed;
    await saveMission(sub);
  }

  /// Tomar o soltar una misión principal.
  /// Tomada = aparece en el main; suelta = solo en el tablón.
  static Future<void> toggleTaken(Mission mission) async {
    if (mission.parentId != null) return; // solo principales
    mission.taken = !mission.taken;
    await saveMission(mission);
  }

  /// Misiones principales TOMADAS, para el main.
  /// Mismo orden que el tablón: por fechaInicio, sin fecha al final.
  static List<Mission> getTomadas() {
    return getPrincipales().where((m) => m.taken).toList();
  }

  /// Completar una misión principal:
  /// guarda en historial, genera el pago y archiva la misión con sus hijas.
  static Future<void> completeMission(Mission mission) async {
    if (mission.parentId != null) return; // solo principales

    final histBox = MissionHiveService.getMissionHistoryBox();

    int nextId = 1;
    for (final h in histBox.values) {
      if (h.id >= nextId) nextId = h.id + 1;
    }

    // Snapshot: si mañana editas la misión, el historial no cambia
    await histBox.add(
      MissionHistory(
        id: nextId,
        missionId: mission.id,
        nombre: mission.nombre,
        valorSnapshot: mission.valor,
        completedAt: DateTime.now(),
      ),
    );

    // Generar el pago pendiente
    await CashOutService.generarPagoMision(
      nombre: mission.nombre,
      valor: mission.valor,
    );

    // Soft delete en cascada: la misión y todas sus hijas
    final now = DateTime.now();
    final box = MissionHiveService.getMissionBox();
    for (final k in box.keys) {
      final m = box.get(k);
      if (m == null || m.deletedAt != null) continue;
      if (m.id == mission.id || m.parentId == mission.id) {
        m.deletedAt = now;
        await box.put(k, m);
      }
    }

    print('🏁 Misión completada: ${mission.nombre} (paga ${mission.valor})');
  }

  /// Eliminar sin completar: soft delete en cascada, sin historial ni pago
  static Future<void> deleteMission(Mission mission) async {
    final now = DateTime.now();
    final box = MissionHiveService.getMissionBox();

    for (final k in box.keys) {
      final m = box.get(k);
      if (m == null || m.deletedAt != null) continue;

      final esLaMision = m.id == mission.id;
      final esHija = mission.parentId == null && m.parentId == mission.id;

      if (esLaMision || esHija) {
        m.deletedAt = now;
        await box.put(k, m);
      }
    }

    print('🗑 Misión eliminada: ${mission.nombre}');
  }
}
