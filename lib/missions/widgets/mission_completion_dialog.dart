import 'package:flutter/material.dart';
import 'package:asend/models/mission.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/missions/services/mission_service.dart';

/// Confirma y completa una misión principal.
/// Al aceptar: se guarda en historial, se genera el pago y
/// la misión desaparece junto con todas sus submisiones.
Future<void> showMissionCompletionDialog(
  BuildContext context,
  Mission mission,
  VoidCallback onRefresh,
) async {
  final subs = MissionService.getSubmisiones(mission.id);
  final pendientes = subs.where((s) => !s.completed).length;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.bgDarkGrey,
      title: const Text(
        '¿Completar misión?',
        style: TextStyle(color: AppTheme.textWhite),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${mission.nombre}"',
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Se registrará un pago de ${mission.valor}.',
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          if (pendientes > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Tienes $pendientes submisión(es) sin marcar. '
              'Se completarán junto con la misión.',
              style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text(
            'Completar',
            style: TextStyle(color: AppTheme.success),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await MissionService.completeMission(mission);
  onRefresh();
}
