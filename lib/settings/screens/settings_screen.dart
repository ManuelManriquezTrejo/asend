import 'package:asend/bank/services/reconciliation_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Configuración de la app, desde el engranaje del inicio.
/// Por ahora solo tiene los avisos; aquí también irá el tema.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: EdgeInsets.all(e.w(5)),
        children: [
          _titulo(e, 'Notificaciones'),
          _interruptor(
            e,
            titulo: 'Diferencias en Banco',
            descripcion: 'Punto rojo cuando un cuadre no cuadra',
            valor: ReconciliationService.avisosActivos(),
            onChanged: (v) async {
              await ReconciliationService.setAvisosActivos(v);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _titulo(Escala e, String texto) {
    return Padding(
      padding: EdgeInsets.only(bottom: e.h(1)),
      child: Text(
        texto,
        style: TextStyle(
          color: AppTheme.buttonPurple,
          fontSize: e.t(4.8),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _interruptor(
    Escala e, {
    required String titulo,
    required String descripcion,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: e.h(1.5)),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        borderRadius: BorderRadius.circular(e.t(2.5)),
      ),
      child: SwitchListTile(
        value: valor,
        onChanged: onChanged,
        activeThumbColor: AppTheme.buttonPurple,
        title: Text(
          titulo,
          style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4.2)),
        ),
        subtitle: Text(
          descripcion,
          style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.5)),
        ),
      ),
    );
  }
}