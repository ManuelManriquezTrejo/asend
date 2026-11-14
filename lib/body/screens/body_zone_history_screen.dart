import 'package:asend/body/services/body_service.dart';
import 'package:asend/models/body_measurement.dart';
import 'package:asend/models/body_zone.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Historial de mediciones de una zona. Permite corregir el valor
/// o eliminar cualquier medición, sin importar su fecha.
class BodyZoneHistoryScreen extends StatefulWidget {
  final BodyZone zona;

  const BodyZoneHistoryScreen({super.key, required this.zona});

  @override
  State<BodyZoneHistoryScreen> createState() => _BodyZoneHistoryScreenState();
}

class _BodyZoneHistoryScreenState extends State<BodyZoneHistoryScreen> {
  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Quita el .0 de los enteros: 92.5 se queda, 80.0 sale como 80.
  String _numero(double v) => v.toString().replaceAll(RegExp(r'\.0$'), '');

  // ── Corregir ───────────────────────────────────────────

  Future<void> _corregir(BodyMeasurement medicion) async {
    final controlador = TextEditingController(text: _numero(medicion.valor));
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Corregir ${_fecha(medicion.fecha)}',
            style: const TextStyle(color: AppTheme.textWhite),
          ),
          content: TextField(
            controller: controlador,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Números, punto y coma: algunos teclados solo dan coma
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              suffixText: medicion.unidadSnapshot,
              errorText: error,
            ),
            onChanged: (_) {
              if (error != null) setDialogState(() => error = null);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final mensaje = BodyService.validarValor(controlador.text);

                if (mensaje != null) {
                  setDialogState(() => error = mensaje);
                  return;
                }

                final navigator = Navigator.of(context);

                await BodyService.corregirMedicion(
                  medicion,
                  BodyService.parsearValor(controlador.text),
                );

                navigator.pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    // El TextField sigue usando el controlador durante la animación
    // de cierre; liberarlo antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    controlador.dispose();

    if (mounted) setState(() {});
  }

  // ── Eliminar ───────────────────────────────────────────

  Future<void> _eliminar(BodyMeasurement medicion) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Eliminar medición?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Se eliminará ${_numero(medicion.valor)} '
          '${medicion.unidadSnapshot} del ${_fecha(medicion.fecha)}.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    await BodyService.eliminarMedicion(medicion);
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Medición eliminada')));
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mediciones = BodyService.getMedicionesDeZona(widget.zona.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.zona.nombre)),
      body: mediciones.isEmpty
          ? _vacio()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: mediciones.map(_tarjeta).toList(),
            ),
    );
  }

  Widget _vacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.straighten, size: 56, color: AppTheme.textHint),
          SizedBox(height: 16),
          Text(
            'Aún no hay mediciones',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(BodyMeasurement medicion) {
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
            '${_numero(medicion.valor)} ${medicion.unidadSnapshot}',
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _fecha(medicion.fecha),
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppTheme.textHint,
                  size: 20,
                ),
                onPressed: () => _corregir(medicion),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.danger,
                  size: 20,
                ),
                onPressed: () => _eliminar(medicion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}