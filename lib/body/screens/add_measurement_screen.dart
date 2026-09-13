import 'package:asend/body/services/body_service.dart';
import 'package:asend/models/body_zone.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddMeasurementScreen extends StatefulWidget {
  const AddMeasurementScreen({super.key});

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  /// Todas las zonas activas, en orden. El recorrido las visita todas
  /// para poder retroceder a corregir una ya guardada.
  late final List<BodyZone> _zonas = BodyService.getZonas();

  late int _indice;
  final _controlador = TextEditingController();
  String? _error;
  bool _guardando = false;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();

    // Arrancar en la primera zona sin medición de hoy.
    // Si sales a media medición, al volver continúas ahí.
    final pendiente = _zonas.indexWhere(
      (z) => BodyService.getMedicionDeHoy(z.id) == null,
    );

    _indice = pendiente == -1 ? 0 : pendiente;
    _cargarValor();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  BodyZone get _zona => _zonas[_indice];

  bool get _esUltima => _indice == _zonas.length - 1;

  /// Precarga el valor de hoy de la zona actual, si ya existe.
  void _cargarValor() {
    final medicion = BodyService.getMedicionDeHoy(_zona.id);

    _controlador.text = medicion == null
        ? ''
        : medicion.valor.toString().replaceAll(RegExp(r'\.0$'), '');
    _error = null;
  }

  // ── Navegación entre zonas ─────────────────────────────

  Future<void> _siguiente() async {
    final error = BodyService.validarValor(_controlador.text);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _guardando = true);

    await BodyService.guardarMedicion(
      zona: _zona,
      valor: BodyService.parsearValor(_controlador.text),
    );

    if (!mounted) return;

    setState(() {
      _guardando = false;

      if (_esUltima) {
        _terminado = true;
      } else {
        _indice++;
        _cargarValor();
      }
    });
  }

  void _atras() {
    if (_indice == 0) {
      _confirmarSalida();
      return;
    }

    setState(() {
      _indice--;
      _cargarValor();
    });
  }

  /// Pregunta antes de abandonar el recorrido.
  /// Lo ya guardado se conserva.
  Future<void> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Salir de la medición?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: const Text(
          'Lo que ya guardaste se conserva. '
          'Al volver hoy, continúas donde quedaste.',
          style: TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Seguir midiendo',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Salir',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (salir == true && mounted) Navigator.pop(context);
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_terminado) return _pantallaFinal();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmarSalida();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agregar medidas'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmarSalida,
          ),
        ),
        body: Column(
          children: [
            _avance(),
            Expanded(child: _campo()),
            _botones(),
          ],
        ),
      ),
    );
  }

  Widget _avance() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zona ${_indice + 1} de ${_zonas.length}',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_indice + 1) / _zonas.length,
              minHeight: 6,

              valueColor: const AlwaysStoppedAnimation(AppTheme.buttonPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _zona.nombre,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controlador,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Números, punto y coma: algunos teclados solo dan coma
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: _zona.unidad,
              suffixStyle: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 18,
              ),
              errorText: _error,
              errorStyle: const TextStyle(fontSize: 13),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _siguiente(),
          ),
        ],
      ),
    );
  }

  Widget _botones() {
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
            flex: 2,
            child: OutlinedButton(
              onPressed: _guardando ? null : _atras,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppTheme.buttonPurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _indice == 0 ? 'Salir' : 'Atrás',
                style: const TextStyle(color: AppTheme.buttonPurple),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _guardando ? null : _siguiente,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(_esUltima ? 'Finalizar' : 'Siguiente'),
            ),
          ),
        ],
      ),
    );
  }

  /// Pantalla de cierre. Solo sale de aquí con el botón.
  Widget _pantallaFinal() {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 72,
                  color: AppTheme.success,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Medidas guardadas correctamente',
                  style: TextStyle(color: AppTheme.textWhite, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(180, 48),
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
