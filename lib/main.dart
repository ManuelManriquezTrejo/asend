import 'package:asend/database/birthday_hive_service.dart';
import 'package:asend/database/body_hive_service.dart';
import 'package:asend/database/cash_out_hive_service.dart';
import 'package:asend/database/chart_hive_service.dart';
import 'package:asend/database/goal_hive_service.dart';
import 'package:asend/database/gym_hive_service.dart';
import 'package:asend/database/hive_service.dart';
import 'package:asend/database/mission_hive_service.dart';
import 'package:asend/database/routine_hive_service.dart';
import 'package:asend/database/store_hive_service.dart';
import 'package:asend/home/widgets/module_bar.dart';
import 'package:asend/missions/services/mission_service.dart';
import 'package:asend/missions/widgets/mission_completion_dialog.dart';
import 'package:asend/models/daily_routine_habit.dart';
import 'package:asend/routine/services/day_change_service.dart';
import 'package:asend/routine/services/habit_history_service.dart';
import 'package:asend/routine/widgets/habit_completion_dialogs.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Hive del Banco
  await HiveService.initializeHive();

  // Inicializar Hive de Rutina
  await RoutineHiveService.initializeRoutineHive();

  // Inicializar Hive de Misiones
  await MissionHiveService.initializeMissionHive();

  // Inicializar Hive de CashOut
  await CashOutHiveService.initializeCashOutHive();

  // Inicializar Hive de Metas
  await GoalHiveService.initializeGoalHive();

  // Inicializar Hive de Tienda
  await StoreHiveService.initializeStoreHive();

  // Inicializar Hive de Cumpleaños
  await BirthdayHiveService.initializeBirthdayHive();

  // Inicializar Hive de Medidas
  await BodyHiveService.initializeBodyHive();

  // Inicializar Hive de Gym
  await GymHiveService.initializeGymHive();

    // Inicializar Hive de Gráficas
  await ChartHiveService.initializeChartHive();

  // Ver datos en consola
  HiveService.printFondos();
  HiveService.printAllData();
  //RoutineHiveService.printAllData();
  //MissionHiveService.printAllData();
  CashOutHiveService.printAllData();
  GoalHiveService.printAllData();
  StoreHiveService.printAllData();
  //BirthdayHiveService.printAllData();
  BodyHiveService.printAllData();
  GymHiveService.printAllData();
  ChartHiveService.printAllData();

  // Asend es de uso vertical: bloquear la rotación evita
  // los overflow de las pantallas al acostar el teléfono
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Ejecutar la app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asend',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Misiones desplegadas para ver sus submisiones
  final Set<int> _expandidas = {};

  @override
  void initState() {
    super.initState();

    // Detectar cambios de día y refrescar automáticamente
    DayChangeService.startDayChangeListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    DayChangeService.stopDayChangeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Misiones tomadas, ordenadas por fecha de inicio
    final misiones = MissionService.getTomadas();

    // Obtener hábitos de la base de datos
    final habitBox = RoutineHiveService.getDailyRoutineHabitBox();
    final habits = habitBox.values
        .cast<DailyRoutineHabit>()
        .where((h) => h.deletedAt == null) // Solo activos
        .toList();

    // Ordenar por prioridad
    habits.sort((a, b) => a.prioridad.compareTo(b.prioridad));

    // Filtrar solo incompletos de hoy
    final incompleteHabits = habits.where((habit) {
      return !HabitHistoryService.isHabitRecordedToday(habit.id);
    }).toList();

    bool allCompleted = incompleteHabits.isEmpty && misiones.isEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        return Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppTheme.buttonPurple,
      backgroundColor: AppTheme.bgDarkGrey,
      child: Scaffold(
        body: Column(
          children: [
            // 1. Margen superior 5%
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // 2. Título "Bienvenido a Asend"
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Bienvenido a Asend',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.buttonPurple,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // 3. Mensaje de actividades
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                allCompleted
                    ? '¡Felicidades! Tuviste un día muy productivo 🎉'
                    : 'Actividades pendientes',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // 4. Lista scrolleable: misiones primero, luego hábitos
            Expanded(
              child: allCompleted
                  ? Container()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // ── MISIONES ──────────────────────────────
                        ...misiones.map((m) {
                          final subs = MissionService.getSubmisiones(m.id);
                          final abierta = _expandidas.contains(m.id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: AppTheme.bgDarkGrey,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: AppTheme.buttonPurple.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      m.nombre,
                                      style: const TextStyle(
                                        color: AppTheme.textWhite,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      subs.isEmpty
                                          ? 'Misión · Paga ${m.valor}'
                                          : 'Misión · Paga ${m.valor} · '
                                                '${subs.where((s) => s.completed).length}'
                                                '/${subs.length} pasos',
                                      style: const TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    // Tocar la fila despliega las submisiones
                                    onTap: subs.isEmpty
                                        ? null
                                        : () => setState(() {
                                            if (abierta) {
                                              _expandidas.remove(m.id);
                                            } else {
                                              _expandidas.add(m.id);
                                            }
                                          }),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (subs.isNotEmpty)
                                          Icon(
                                            abierta
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            color: AppTheme.textHint,
                                            size: 20,
                                          ),
                                        Checkbox(
                                          value: false,
                                          onChanged: (_) {
                                            showMissionCompletionDialog(
                                              context,
                                              m,
                                              () => setState(() {}),
                                            );
                                          },
                                          fillColor: WidgetStateProperty.all(
                                            AppTheme.buttonPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Submisiones desplegadas
                                  if (abierta)
                                    ...subs.map(
                                      (s) => ListTile(
                                        dense: true,
                                        contentPadding: const EdgeInsets.only(
                                          left: 32,
                                          right: 16,
                                        ),
                                        leading: Checkbox(
                                          value: s.completed,
                                          onChanged: (_) async {
                                            await MissionService.toggleSubmision(
                                              s,
                                            );
                                            if (!mounted) return;
                                            setState(() {});
                                          },
                                          fillColor: WidgetStateProperty.all(
                                            AppTheme.buttonPurple,
                                          ),
                                        ),
                                        title: Text(
                                          s.nombre,
                                          style: TextStyle(
                                            color: s.completed
                                                ? AppTheme.textHint
                                                : AppTheme.textWhite,
                                            fontSize: 13,
                                            decoration: s.completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // ── HÁBITOS ───────────────────────────────
                        ...incompleteHabits.map((habit) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: AppTheme.bgDarkGrey,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: AppTheme.buttonPurple.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  habit.nombre,
                                  style: const TextStyle(
                                    color: AppTheme.textWhite,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Racha: ${habit.currentStreak} días',
                                  style: const TextStyle(
                                    color: AppTheme.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: false,
                                  onChanged: (_) {
                                    showHabitCompletionDialog(
                                      context,
                                      habit,
                                      () => setState(() {}),
                                    );
                                  },
                                  fillColor: WidgetStateProperty.all(
                                    AppTheme.buttonPurple,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),

            // 5. Barra de módulos: Economía, Actividades y Datos
            ModuleBar(
              onVolver: () {
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
