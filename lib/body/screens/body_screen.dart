import 'package:asend/body/screens/add_measurement_screen.dart';
import 'package:asend/body/services/body_service.dart';
import 'package:asend/models/body_zone.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ── Crear y editar zona ────────────────────────────────

  /// Diálogo compartido por crear y editar.
  /// Con [zona] en null crea una nueva.
  Future<void> _dialogoZona({BodyZone? zona}) async {
    final esNueva = zona == null;
    final controlador = TextEditingController(text: zona?.nombre ?? '');
    String unidad = zona?.unidad ?? BodyService.unidades.first;
    String? error;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                esNueva ? 'Nueva zona' : 'Editar zona',
                style: const TextStyle(color: AppTheme.textWhite),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controlador,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      hintText: 'Bíceps, cintura, peso...',
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Unidad',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: BodyService.unidades.map((u) {
                      final elegida = u == unidad;

                      return ChoiceChip(
                        label: Text(u),
                        selected: elegida,
                        onSelected: (_) => setDialogState(() => unidad = u),
                        backgroundColor: AppTheme.bgDark,
                        selectedColor: AppTheme.buttonPurple,
                        labelStyle: TextStyle(
                          color: elegida
                              ? AppTheme.textWhite
                              : AppTheme.textGrey,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: elegida
                              ? AppTheme.buttonPurple
                              : AppTheme.textHint,
                        ),
                      );
                    }).toList(),
                  ),
                ],
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
                    final nombre = controlador.text.trim();

                    if (nombre.isEmpty) {
                      setDialogState(() => error = 'Escribe un nombre');
                      return;
                    }
                    if (BodyService.existeNombreZona(
                      nombre,
                      exceptoId: zona?.id,
                    )) {
                      setDialogState(() => error = 'Ya existe esa zona');
                      return;
                    }

                    final navigator = Navigator.of(context);

                    if (esNueva) {
                      await BodyService.crearZona(
                        nombre: nombre,
                        unidad: unidad,
                      );
                    } else {
                      await BodyService.editarZona(
                        zona,
                        nombre: nombre,
                        unidad: unidad,
                      );
                    }

                    navigator.pop();
                  },
                  child: Text(esNueva ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    // El TextField sigue usando el controlador durante la animación
    // de cierre; liberarlo antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    controlador.dispose();

    if (mounted) setState(() {});
  }
  // ── Eliminar zona ──────────────────────────────────────

  Future<void> _eliminarZona() async {
    final zonas = BodyService.getZonas();

    if (zonas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay zonas para eliminar')),
      );
      return;
    }

    // 1. Escoger cuál
    final elegida = await showDialog<BodyZone>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Eliminar zona',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: zonas
                .map(
                  (z) => ListTile(
                    title: Text(
                      z.nombre,
                      style: const TextStyle(color: AppTheme.textWhite),
                    ),
                    subtitle: Text(
                      z.unidad,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, z),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );

    if (elegida == null || !mounted) return;

    // 2. Confirmar
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Eliminar zona?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Se eliminará "${elegida.nombre}".\n\n'
          'Sus mediciones se conservan.',
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

    await BodyService.eliminarZona(elegida);
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${elegida.nombre} eliminada')));
  }

  // ── Agregar medidas ────────────────────────────────────

  void _agregarMedidas() {
    if (BodyService.getZonas().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea una zona antes de medir')),
      );
      return;
    }

    if (BodyService.yaMidioTodoHoy()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya se realizaron las medidas de hoy')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMeasurementScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final zonas = BodyService.getZonas();

    return Scaffold(
      appBar: AppBar(title: const Text('Medidas de cuerpo')),
      body: Column(
        children: [
          Expanded(child: zonas.isEmpty ? _vacio() : _lista(zonas)),
          _barraInferior(),
        ],
      ),
    );
  }

  Widget _vacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.straighten, size: 56, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text(
            'Aún no hay zonas para medir',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _dialogoZona(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar zona'),
          ),
        ],
      ),
    );
  }

  Widget _lista(List<BodyZone> zonas) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        ...zonas.map(_tarjetaZona),
        const SizedBox(height: 8),
        // Agregar zona va al final de la lista
        OutlinedButton.icon(
          onPressed: () => _dialogoZona(),
          icon: const Icon(Icons.add, color: AppTheme.buttonPurple),
          label: const Text(
            'Agregar zona',
            style: TextStyle(color: AppTheme.buttonPurple),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: AppTheme.buttonPurple),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaZona(BodyZone zona) {
    final ultima = BodyService.getUltimaMedicion(zona.id);
    final medidaHoy = BodyService.getMedicionDeHoy(zona.id) != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgDarkGrey,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: medidaHoy
                ? AppTheme.success.withValues(alpha: 0.5)
                : AppTheme.buttonPurple.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          title: Text(
            zona.nombre,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            ultima == null
                ? 'Sin mediciones · ${zona.unidad}'
                : '${ultima.valor} ${ultima.unidadSnapshot} · '
                      '${_fecha(ultima.fecha)}',
            style: TextStyle(
              color: medidaHoy ? AppTheme.success : AppTheme.textGrey,
              fontSize: 12,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.textHint, size: 20),
            onPressed: () => _dialogoZona(zona: zona),
          ),
        ),
      ),
    );
  }

  Widget _barraInferior() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).size.height * 0.02,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: _agregarMedidas,
              icon: const Icon(Icons.straighten, size: 18),
              label: const Text('Agregar medidas'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _eliminarZona,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Eliminar zona',
                style: TextStyle(color: AppTheme.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
