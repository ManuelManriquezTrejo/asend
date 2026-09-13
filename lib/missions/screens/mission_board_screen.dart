import 'package:flutter/material.dart';
import 'package:asend/models/mission.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/missions/services/mission_service.dart';
import 'add_mission_screen.dart';
import 'edit_mission_screen.dart';

class MissionBoardScreen extends StatefulWidget {
  const MissionBoardScreen({super.key});

  @override
  State<MissionBoardScreen> createState() => _MissionBoardScreenState();
}

class _MissionBoardScreenState extends State<MissionBoardScreen> {
  String _fecha(DateTime? d) {
    if (d == null) return 'sin fecha';
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _confirmDelete(Mission mission) async {
    final subs = MissionService.getSubmisiones(mission.id);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          '¿Eliminar misión?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          subs.isEmpty
              ? '"${mission.nombre}" se eliminará sin generar pago.'
              : '"${mission.nombre}" y sus ${subs.length} submisiones se '
                    'eliminarán sin generar pago.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await MissionService.deleteMission(mission);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final principales = MissionService.getPrincipales();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablón de Misiones'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: principales.isEmpty
                ? const Center(
                    child: Text(
                      'No hay misiones activas',
                      style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: principales.length,
                    itemBuilder: (context, index) {
                      final m = principales[index];
                      final subs = MissionService.getSubmisiones(m.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgDarkGrey,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.buttonPurple.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Theme(
                            // Quita las líneas divisorias del ExpansionTile
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              leading: Checkbox(
                                value: m.taken,
                                onChanged: (_) async {
                                  await MissionService.toggleTaken(m);
                                  if (!mounted) return;
                                  setState(() {});
                                },
                                fillColor: WidgetStateProperty.all(
                                  AppTheme.buttonPurple,
                                ),
                              ),
                              title: Text(
                                m.nombre,
                                style: const TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Paga ${m.valor} · Inicio: ${_fecha(m.fechaInicio)}'
                                ' · Límite: ${_fecha(m.fechaLimite)}',
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: AppTheme.buttonPurple,
                                    tooltip: 'Modificar',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EditMissionScreen(mission: m),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
                                  ),
                                  const Icon(
                                    Icons.expand_more,
                                    color: AppTheme.textHint,
                                  ),
                                ],
                              ),
                              children: [
                                // Submisiones
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
                                        await MissionService.toggleSubmision(s);
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
                                    subtitle: Text(
                                      'Inicio: ${_fecha(s.fechaInicio)}'
                                      ' · Límite: ${_fecha(s.fechaLimite)}',
                                      style: const TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 10,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
                                          color: AppTheme.buttonPurple,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EditMissionScreen(
                                                      mission: s,
                                                    ),
                                              ),
                                            ).then((_) => setState(() {}));
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                          ),
                                          color: AppTheme.danger,
                                          onPressed: () => _confirmDelete(s),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Acciones de la misión principal
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text(
                                            'Submisión',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddMissionScreen(
                                                      parentId: m.id,
                                                    ),
                                              ),
                                            ).then((_) => setState(() {}));
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Eliminar',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.danger,
                                          ),
                                          onPressed: () => _confirmDelete(m),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddMissionScreen()),
                  ).then((_) => setState(() {}));
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Agregar Misión',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
