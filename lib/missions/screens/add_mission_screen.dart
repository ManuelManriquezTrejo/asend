import 'package:flutter/material.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/missions/services/mission_service.dart';

class AddMissionScreen extends StatefulWidget {
  /// null = misión principal; con valor = submisión de esa misión
  final int? parentId;

  const AddMissionScreen({super.key, this.parentId});

  @override
  State<AddMissionScreen> createState() => _AddMissionScreenState();
}

class _AddMissionScreenState extends State<AddMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _valorController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaLimite;
  bool _isLoading = false;

  bool get _esSubmision => widget.parentId != null;

  @override
  void dispose() {
    _nombreController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _pickFecha(bool esInicio) async {
    final ahora = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (esInicio ? _fechaInicio : _fechaLimite) ?? ahora,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = picked;
      } else {
        _fechaLimite = picked;
      }
    });
  }

  String _fechaTexto(DateTime? d) =>
      d == null ? 'Sin fecha' : '${d.day}/${d.month}/${d.year}';

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await MissionService.createMission(
        nombre: _nombreController.text.trim(),
        parentId: widget.parentId,
        valor: _esSubmision ? 0.0 : double.parse(_valorController.text),
        fechaInicio: _fechaInicio,
        fechaLimite: _fechaLimite,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esSubmision ? 'Submisión creada' : 'Misión creada'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
      setState(() => _isLoading = false);
    }
  }

  Widget _label(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      texto,
      style: const TextStyle(
        color: AppTheme.textWhite,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _fechaSelector(String titulo, bool esInicio) {
    final valor = esInicio ? _fechaInicio : _fechaLimite;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.buttonPurple),
      ),
      child: ListTile(
        title: Text(
          titulo,
          style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
        ),
        subtitle: Text(
          _fechaTexto(valor),
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
        ),
        trailing: valor == null
            ? const Icon(
                Icons.calendar_today,
                color: AppTheme.buttonPurple,
                size: 20,
              )
            : IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: AppTheme.textHint,
                  size: 20,
                ),
                onPressed: () => setState(() {
                  if (esInicio) {
                    _fechaInicio = null;
                  } else {
                    _fechaLimite = null;
                  }
                }),
              ),
        onTap: () => _pickFecha(esInicio),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esSubmision ? 'Agregar Submisión' : 'Agregar Misión'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nombre *'),
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(
                  hintText: 'Ej: Arreglar la bicicleta',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 20),

              // Las submisiones no pagan: son control visual
              if (!_esSubmision) ...[
                _label('Valor (pago al completar) *'),
                TextFormField(
                  controller: _valorController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(hintText: 'Ej: 50'),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'El valor es obligatorio';
                    final d = double.tryParse(v);
                    if (d == null) return 'Ingresa un número válido';
                    if (d < 0) return 'No puede ser negativo';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              _label('Fechas (opcionales)'),
              _fechaSelector('Fecha de inicio', true),
              const SizedBox(height: 12),
              _fechaSelector('Fecha límite', false),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppTheme.textWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _esSubmision ? 'Crear Submisión' : 'Crear Misión',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
