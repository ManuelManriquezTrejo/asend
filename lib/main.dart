import 'package:asend/bank/screens/pay_debt_screen.dart';
import 'package:asend/bank/services/debt_service.dart';
import 'package:asend/birthdays/screens/birthdays_screen.dart';
import 'package:asend/birthdays/services/birthday_service.dart';
import 'package:asend/database/birthday_hive_service.dart';
import 'package:asend/database/body_hive_service.dart';
import 'package:asend/database/cash_out_hive_service.dart';
import 'package:asend/database/chart_hive_service.dart';
import 'package:asend/database/debt_hive_service.dart';
import 'package:asend/database/goal_hive_service.dart';
import 'package:asend/database/gym_hive_service.dart';
import 'package:asend/database/hive_service.dart';
import 'package:asend/database/mission_hive_service.dart';
import 'package:asend/database/routine_hive_service.dart';
import 'package:asend/database/store_hive_service.dart';
import 'package:asend/home/widgets/module_bar.dart';
import 'package:asend/missions/services/mission_service.dart';
import 'package:asend/missions/widgets/mission_completion_dialog.dart';
import 'package:asend/models/birthday.dart';
import 'package:asend/models/daily_routine_habit.dart';
import 'package:asend/models/debt_installment.dart';
import 'package:asend/models/mission.dart';
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

  // Inicializar Hive de Deuda
  await DebtHiveService.initializeDebtHive();

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
  DebtHiveService.printAllData();

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
      debugShowCheckedModeBanner: false,
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
  /// Cumpleaños que se muestran: hoy y los próximos 45 días.
  static const int _diasCumple = 45;

  static const List<String> _mesesCortos = [
    '',
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  // Misiones desplegadas para ver sus submisiones
  final Set<int> _expandidas = {};

  // Apartados abiertos. No se guardan: al abrir la app, todos abiertos.
  bool _verCumples = true;
  bool _verMisiones = true;
  bool _verRutina = true;

  @override
  void initState() {
    super.initState();

    // Crear las mensualidades de suscripción que falten, para que los
    // pagos de hoy aparezcan aunque no se haya abierto Banco
    _actualizarDeuda();

    // Detectar cambios de día y refrescar automáticamente
    DayChangeService.startDayChangeListener(() {
      _actualizarDeuda();
    });
  }

  Future<void> _actualizarDeuda() async {
    await DebtService.generarSuscripciones();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DayChangeService.stopDayChangeListener();
    super.dispose();
  }

  /// Abre la pantalla de Pagar de Banco y refresca al volver.
  void _abrirPagar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PayDebtScreen()),
    ).then((_) => _actualizarDeuda());
  }

  /// Abre Cumpleaños directo en el menú de editar de esa persona.
  void _abrirCumple(Birthday b) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BirthdaysScreen(editarPersona: b),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cumpleaños de hoy y los próximos 45 días, del más cercano al más lejano
    final cumples = BirthdayService.getTodos()
        .where((b) => BirthdayService.diasFaltantes(b) <= _diasCumple)
        .toList();

    // Misiones tomadas, ordenadas por fecha de inicio
    final misiones = MissionService.getTomadas();

    // Pagos de deuda con fecha de hoy o anteriores, sin pagar.
    // Se muestran dentro de Misiones, cada uno con su tarjeta.
    final pagosHoy = DebtService.pagosParaHoy();

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

    // Los cumpleaños no son tareas: no cuentan para la felicitación.
    // Los pagos pendientes sí cuentan.
    final bool allCompleted =
        incompleteHabits.isEmpty && misiones.isEmpty && pagosHoy.isEmpty;

    // Misiones aparece si hay misiones tomadas o pagos para hoy
    final bool hayMisiones = misiones.isNotEmpty || pagosHoy.isNotEmpty;

    // Un apartado vacío desaparece completo, con todo y su título
    final bool hayAlgo =
        cumples.isNotEmpty || hayMisiones || incompleteHabits.isNotEmpty;

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

            // 4. Apartados: cumpleaños, misiones y rutina
            Expanded(
              child: !hayAlgo
                  ? Container()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // ── CUMPLEAÑOS ────────────────────────────
                        if (cumples.isNotEmpty) ...[
                          _encabezado(
                            titulo: 'Cumpleaños',
                            cantidad: cumples.length,
                            abierto: _verCumples,
                            onTap: () =>
                                setState(() => _verCumples = !_verCumples),
                          ),
                          if (_verCumples) ...cumples.map(_tarjetaCumple),
                        ],

                        // ── MISIONES ──────────────────────────────
                        if (hayMisiones) ...[
                          _encabezado(
                            titulo: 'Misiones',
                            cantidad: misiones.length + pagosHoy.length,
                            abierto: _verMisiones,
                            onTap: () =>
                                setState(() => _verMisiones = !_verMisiones),
                          ),
                          if (_verMisiones) ...[
                            // Los pagos van primero porque ya tocan
                            ...pagosHoy.map(_tarjetaPago),
                            ...misiones.map(_tarjetaMision),
                          ],
                        ],

                        // ── RUTINA ────────────────────────────────
                        if (incompleteHabits.isNotEmpty) ...[
                          _encabezado(
                            titulo: 'Rutina',
                            cantidad: incompleteHabits.length,
                            abierto: _verRutina,
                            onTap: () =>
                                setState(() => _verRutina = !_verRutina),
                          ),
                          if (_verRutina)
                            ...incompleteHabits.map(_tarjetaHabito),
                        ],
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

  // ── Encabezado de apartado ───────────────────────────────

  /// Título con su cantidad. Tocarlo muestra u oculta el apartado.
  Widget _encabezado({
    required String titulo,
    required int cantidad,
    required bool abierto,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$titulo ($cantidad)',
                style: const TextStyle(
                  color: AppTheme.buttonPurple,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              abierto ? Icons.expand_less : Icons.expand_more,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  // ── Cumpleaños ──────────────────────────────────────────

  Widget _tarjetaCumple(Birthday b) {
    final dias = BirthdayService.diasFaltantes(b);
    final esHoy = dias == 0;

    // Si hoy es su cumpleaños ya cumplió; si no, cumplirá uno más.
    // Sin año registrado no se sabe, y se deja vacío.
    final edad = BirthdayService.edadActual(b);
    final cumple = edad == null ? null : (esHoy ? edad : edad + 1);

    final cuando = esHoy
        ? 'Hoy'
        : dias == 1
        ? 'Mañana'
        : 'En $dias días';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgDarkGrey,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: esHoy
                ? AppTheme.success
                : AppTheme.buttonPurple.withValues(alpha: 0.3),
            width: esHoy ? 2 : 1,
          ),
        ),
        child: ListTile(
          leading: Icon(
            Icons.cake,
            color: esHoy ? AppTheme.success : AppTheme.buttonPurple,
          ),
          title: Text(
            b.nombre,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${b.dia} ${_mesesCortos[b.mes]} · $cuando',
            style: TextStyle(
              color: esHoy ? AppTheme.success : AppTheme.textGrey,
              fontSize: 12,
            ),
          ),
          trailing: cumple == null
              ? null
              : Text(
                  'Cumple $cumple',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
          onTap: () => _abrirCumple(b),
        ),
      ),
    );
  }

  // ── Pagos de deuda ──────────────────────────────────────

  /// Tarjeta de un pago para hoy o vencido. No tiene casilla: se quita
  /// sola cuando se paga en Banco. Tocarla abre la pantalla de Pagar.
  Widget _tarjetaPago(DebtInstallment c) {
    final vencido = DebtService.estaVencida(c);
    final fecha = '${c.fechaPago.day} ${_mesesCortos[c.fechaPago.month]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgDarkGrey,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: vencido ? AppTheme.danger : AppTheme.success,
            width: 2,
          ),
        ),
        child: ListTile(
          leading: Icon(
            Icons.credit_card,
            color: vencido ? AppTheme.danger : AppTheme.success,
          ),
          title: Text(
            'Pagar ${DebtService.nombreDe(c)}',
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            vencido ? 'Vencido · $fecha' : 'Hoy · $fecha',
            style: TextStyle(
              color: vencido ? AppTheme.danger : AppTheme.textGrey,
              fontSize: 12,
            ),
          ),
          trailing: Text(
            '\$${c.monto.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: _abrirPagar,
        ),
      ),
    );
  }

  // ── Misiones ────────────────────────────────────────────

  Widget _tarjetaMision(Mission m) {
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
            color: AppTheme.buttonPurple.withValues(alpha: 0.3),
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
                      abierta ? Icons.expand_less : Icons.expand_more,
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
                    fillColor: WidgetStateProperty.all(AppTheme.buttonPurple),
                  ),
                ],
              ),
            ),

            // Submisiones desplegadas
            if (abierta)
              ...subs.map(
                (s) => ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                  leading: Checkbox(
                    value: s.completed,
                    onChanged: (_) async {
                      await MissionService.toggleSubmision(s);
                      if (!mounted) return;
                      setState(() {});
                    },
                    fillColor: WidgetStateProperty.all(AppTheme.buttonPurple),
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
  }

  // ── Rutina ──────────────────────────────────────────────

  Widget _tarjetaHabito(DailyRoutineHabit habit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgDarkGrey,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: AppTheme.buttonPurple.withValues(alpha: 0.3),
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
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          trailing: Checkbox(
            value: false,
            onChanged: (_) {
              showHabitCompletionDialog(context, habit, () => setState(() {}));
            },
            fillColor: WidgetStateProperty.all(AppTheme.buttonPurple),
          ),
        ),
      ),
    );
  }
}