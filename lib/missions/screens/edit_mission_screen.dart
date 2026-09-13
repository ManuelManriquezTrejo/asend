import 'package:flutter/material.dart';
import 'package:asend/models/mission.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/missions/services/mission_service.dart';

class EditMissionScreen extends StatefulWidget {
  final Mission mission;

  const EditMissionScreen({super.key, required this.mission});

  @override
  State<EditMissionScreen> createState() => _EditMissionScreenState();
}

class _EditMissionScreenState extends State<EditMissionScreen> {
  bool get _esSubmision => widget.mission.parentId != null;

  String _fechaTexto(DateTime? d) =>
      d == null ? 'Sin fecha' : '${d.day}/${d.month}/${d.year}';

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: AppTheme.bgDarkGrey),
    );
  }

  /// Diálogo con campo de texto; devuelve lo escrito o null si cancela
  Future<String?> _askText({
    required String titulo,
    required String valorActual,
    required String hint,
    bool numerico = false,
    String? Function(String)? validar,
  }) async {
    final controller = TextEditingController(text: valorActual);
    String error = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            titulo,
            style: const TextStyle(color: AppTheme.textWhite),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: numerico
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: hint,
                  fillColor: AppTheme.bgDark,
                ),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final texto = controller.text.trim();
                final msg = validar?.call(texto);
                if (msg != null) {
                  setDialogState(() => error = msg);
                  return;
                }
                Navigator.pop(dialogContext, texto);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarNombre() async {
    final nuevo = await _askText(
      titulo: 'Nuevo nombre',
      valorActual: widget.mission.nombre,
      hint: 'Ej: Arreglar la bicicleta',
      validar: (t) => t.isEmpty ? 'El nombre no puede estar vacío' : null,
    );
    if (nuevo == null) return;

    widget.mission.nombre = nuevo;
    await MissionService.saveMission(widget.mission);
    setState(() {});
    _aviso('Nombre actualizado');
  }

  Future<void> _editarValor() async {
    final nuevo = await _askText(
      titulo: 'Pago al completar',
      valorActual: widget.mission.valor.toString(),
      hint: 'Ej: 50',
      numerico: true,
      validar: (t) {
        final v = double.tryParse(t);
        if (v == null) return 'Ingresa un número válido';
        if (v < 0) return 'No puede ser negativo';
        return null;
      },
    );
    if (nuevo == null) return;

    widget.mission.valor = double.parse(nuevo);
    await MissionService.saveMission(widget.mission);
    setState(() {});
    _aviso('Valor actualizado');
  }

  Future<void> _editarFecha(bool esInicio) async {
    final actual = esInicio
        ? widget.mission.fechaInicio
        : widget.mission.fechaLimite;
    final ahora = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: actual ?? ahora,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 5),
    );
    if (picked == null) return;

    if (esInicio) {
      widget.mission.fechaInicio = picked;
    } else {
      widget.mission.fechaLimite = picked;
    }
    await MissionService.saveMission(widget.mission);
    setState(() {});
    _aviso('Fecha actualizada');
  }

  Future<void> _quitarFecha(bool esInicio) async {
    if (esInicio) {
      widget.mission.fechaInicio = null;
    } else {
      widget.mission.fechaLimite = null;
    }
    await MissionService.saveMission(widget.mission);
    setState(() {});
    _aviso('Fecha eliminada');
  }

  Widget _opcion({
    required IconData icono,
    required String titulo,
    required String actual,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgDarkGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.buttonPurple.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          leading: Icon(icono, color: AppTheme.buttonPurple),
          title: Text(
            titulo,
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
          ),
          subtitle: Text(
            actual,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          trailing:
              trailing ??
              const Icon(Icons.chevron_right, color: AppTheme.textHint),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esSubmision ? 'Modificar Submisión' : 'Modificar Misión'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            m.nombre,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¿Qué quieres modificar?',
            style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
          ),
          const SizedBox(height: 12),

          _opcion(
            icono: Icons.label_outline,
            titulo: 'Nombre',
            actual: m.nombre,
            onTap: _editarNombre,
          ),

          // Las submisiones no pagan
          if (!_esSubmision)
            _opcion(
              icono: Icons.attach_money,
              titulo: 'Valor',
              actual: '${m.valor} al completar',
              onTap: _editarValor,
            ),

          _opcion(
            icono: Icons.play_arrow,
            titulo: 'Fecha de inicio',
            actual: _fechaTexto(m.fechaInicio),
            onTap: () => _editarFecha(true),
            trailing: m.fechaInicio == null
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppTheme.textHint,
                      size: 20,
                    ),
                    onPressed: () => _quitarFecha(true),
                  ),
          ),

          _opcion(
            icono: Icons.flag_outlined,
            titulo: 'Fecha límite',
            actual: _fechaTexto(m.fechaLimite),
            onTap: () => _editarFecha(false),
            trailing: m.fechaLimite == null
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppTheme.textHint,
                      size: 20,
                    ),
                    onPressed: () => _quitarFecha(false),
                  ),
          ),
        ],
      ),
    );
  }
}
