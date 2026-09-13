import 'package:asend/config/app_config.dart';
import 'package:asend/routine/services/habit_history_service.dart';
import 'dart:async';

class DayChangeService {
  static Timer? _timer;
  static DateTime? _lastCheckedDate;
  static Function? _onDayChanged;

  /// Iniciar monitoreo de cambio de día
  /// Se ejecuta [callback] cuando se detecta cambio de día (después de DAILY_CUTOFF_HOUR)
  static void startDayChangeListener(Function onDayChanged) {
    _onDayChanged = onDayChanged;
    _lastCheckedDate = null; // Iniciar en null para detectar primera vez

    // Verificar INMEDIATAMENTE (primera ejecución)
    final currentDay = _getCurrentDay();
    if (_lastCheckedDate == null) {
      print('📅 PRIMERA EJECUCIÓN - Auto-rellenando días faltantes...');
      HabitHistoryService.fillMissingDaysWithZero().then((_) {
        if (_onDayChanged != null) {
          _onDayChanged!();
        }
      });
      _lastCheckedDate = currentDay;
    }

    // Verificar cada minuto si cambió el día
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final currentDay = _getCurrentDay();

      if (_lastCheckedDate != null && currentDay != _lastCheckedDate) {
        print('📅 ¡CAMBIO DE DÍA DETECTADO! ${_lastCheckedDate} → $currentDay');

        // Auto-rellenar días faltantes con 0
        await HabitHistoryService.fillMissingDaysWithZero();

        // Ejecutar callback para refrescar HomeScreen
        if (_onDayChanged != null) {
          _onDayChanged!();
        }

        _lastCheckedDate = currentDay;
      }
    });

    print('✅ DayChangeService iniciado');
  }

  /// Detener monitoreo
  static void stopDayChangeListener() {
    _timer?.cancel();
    _timer = null;
    print('❌ DayChangeService detenido');
  }

  /// Obtener "hoy" considerando DAILY_CUTOFF_HOUR
  /// Ej: Si son las 3:59 AM, "hoy" es ayer. Si son las 4:00 AM, "hoy" es hoy.
  static DateTime _getCurrentDay() {
    final now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (now.hour < AppConfig.dailyCutoffHour) {
      // Antes del cutoff = pertenece al día anterior
      today = today.subtract(const Duration(days: 1));
    }

    return today;
  }
}
