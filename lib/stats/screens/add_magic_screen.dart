import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/stats/widgets/stat_widgets.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Agregar una o varias de las 6 magias de fábrica (con todas sus
/// habilidades) y, si se escribe un nombre, también una magia nueva.
/// Todo se agrega con el botón fijo de abajo.
class AddMagicScreen extends StatefulWidget {
  const AddMagicScreen({super.key});

  @override
  State<AddMagicScreen> createState() => _AddMagicScreenState();
}

class _AddMagicScreenState extends State<AddMagicScreen> {
  final Set<String> _elegidas = {};
  final TextEditingController _nombreCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Cuántas magias se van a agregar con lo elegido y lo escrito.
  int get _cuantas =>
      _elegidas.length + (_nombreCtrl.text.trim().isEmpty ? 0 : 1);

  Future<void> _agregar() async {
    if (_cuantas == 0) {
      _aviso('Elige una magia o escribe el nombre de una nueva');
      return;
    }

    setState(() => _guardando = true);

    // La nueva va primero: si su nombre no sirve, no se agrega nada
    if (_nombreCtrl.text.trim().isNotEmpty) {
      final error = await StatService.crearMagia(_nombreCtrl.text);
      if (!mounted) return;
      if (error != null) {
        setState(() => _guardando = false);
        _aviso(error);
        return;
      }
    }

    final disponibles = StatService.plantillasDisponibles();
    await StatService.agregarPlantillas(
      disponibles.where((p) => _elegidas.contains(p.clave)).toList(),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final disponibles = StatService.plantillasDisponibles();

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar magia')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(e.w(5)),
              children: [
                const TituloSeccion('Magias existentes'),
                if (disponibles.isEmpty)
                  Text(
                    'Ya agregaste todas las magias existentes',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: e.t(3.8),
                    ),
                  ),
                for (final p in disponibles)
                  Recuadro(
                    resaltado: _elegidas.contains(p.clave),
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _elegidas.contains(p.clave),
                      activeColor: AppTheme.primary,
                      checkColor: AppTheme.onPrimary,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _elegidas.add(p.clave);
                        } else {
                          _elegidas.remove(p.clave);
                        }
                      }),
                      title: Text(
                        p.nombre,
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: e.t(4.3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${p.habilidades.length} habilidades',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: e.t(3.4),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: e.h(2.5)),
                const TituloSeccion('Crear magia nueva'),
                Text(
                  'Opcional. Empieza sin habilidades; se las agregas después '
                  'desde su lápiz.',
                  style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.3)),
                ),
                SizedBox(height: e.h(1)),
                TextField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: e.t(4.2),
                  ),
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  // Redibuja para que el botón diga cuántas se agregan
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          BarraGuardar(
            texto: _cuantas <= 1 ? 'Agregar magia' : 'Agregar $_cuantas magias',
            onPressed: _guardando ? null : _agregar,
          ),
        ],
      ),
    );
  }
}
