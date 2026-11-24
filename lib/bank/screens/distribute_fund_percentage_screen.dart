import 'package:flutter/material.dart';
import 'package:asend/theme/app_theme.dart';
import 'dart:math';

/// Reparte el 100% de un fondo entre varios elementos con sliders y
/// campos de texto. Si a uno le subes, los otros bajan solos.
///
/// Sirve para las dos partes del fondo: el reparto a Cuentas y el
/// reparto a Dinero. No guarda nada: al tocar el botón entrega los
/// porcentajes a [onListo], que decide qué sigue.
class DistributeFundPercentageScreen extends StatefulWidget {
  /// Texto de arriba, por ejemplo: Distribuye "Sueldo" entre las cuentas
  final String titulo;

  /// Elementos a repartir, en el orden en que se muestran.
  final List<({int id, String nombre})> items;

  /// Porcentajes con los que arranca, por ejemplo al modificar un fondo.
  /// Los elementos que no estén aquí empiezan en 0.1.
  final Map<int, double> iniciales;

  /// Texto del botón de abajo: "Continuar" o "Guardar fondo".
  final String textoBoton;

  /// Recibe {id: porcentaje} cuando ya suman 100.
  final Future<void> Function(Map<int, double> porcentajes) onListo;

  const DistributeFundPercentageScreen({
    super.key,
    required this.titulo,
    required this.items,
    required this.textoBoton,
    required this.onListo,
    this.iniciales = const {},
  });

  @override
  State<DistributeFundPercentageScreen> createState() =>
      _DistributeFundPercentageScreenState();
}

class _DistributeFundPercentageScreenState
    extends State<DistributeFundPercentageScreen> {
  late Map<int, double> percentages;
  late Map<int, TextEditingController> controllers;

  /// Mientras onListo trabaja, el botón queda desactivado
  bool _guardando = false;

  List<int> get _ids => widget.items.map((i) => i.id).toList();

  @override
  void initState() {
    super.initState();
    percentages = {};
    controllers = {};

    for (final id in _ids) {
      percentages[id] = widget.iniciales[id] ?? 0.1;
    }

    // Si al sumar los nuevos se pasa de 100, se quita el excedente al
    // que tiene más porcentaje
    final total = percentages.values.fold<double>(0, (s, v) => s + v);
    if (total > 100) {
      final mayor = _getAccountWithMaxPercentage();
      percentages[mayor] = percentages[mayor]! - (total - 100);
    }

    for (final id in _ids) {
      controllers[id] = TextEditingController(
        text: percentages[id]!.toStringAsFixed(1),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Calcular saldo restante (100 - total actual)
  double _getRemaining() {
    double total = percentages.values.fold(0, (sum, val) => sum + val);
    return 100.0 - total;
  }

  // Obtener el elemento con mayor porcentaje (para restar de ahí)
  int _getAccountWithMaxPercentage({int? excludeAccountId}) {
    int maxAccountId = -1;
    double maxValue = -1;

    for (int accountId in _ids) {
      if (excludeAccountId != null && accountId == excludeAccountId) {
        continue;
      }

      double value = percentages[accountId] ?? 0;
      if (value > maxValue) {
        maxValue = value;
        maxAccountId = accountId;
      }
    }

    if (maxAccountId == -1) {
      return _ids.firstWhere((id) => id != excludeAccountId);
    }

    return maxAccountId;
  }

  // Actualizar porcentaje automáticamente
  void _updatePercentage(int accountId, double newValue) {
    // Si es 0 o negativo, convertir a 0.1
    if (newValue <= 0) {
      newValue = 0.1;
    }

    double oldValue = percentages[accountId] ?? 0;
    double difference = newValue - oldValue;

    // Si se está agregando (aumentando)
    if (difference > 0) {
      double remaining = _getRemaining();

      // Si no hay suficiente restante
      if (remaining - difference < 0) {
        // Con un solo elemento no hay de dónde restar
        if (_ids.length == 1) {
          newValue = oldValue + remaining;
        } else {
          // Restar del que tiene mayor porcentaje
          int maxAccountId = _getAccountWithMaxPercentage(
            excludeAccountId: accountId,
          );
          double maxValue = percentages[maxAccountId] ?? 0;
          double neededAmount = difference - remaining;

          // Verificar que no baje de 0.1%
          if (maxValue - neededAmount >= 0.1) {
            percentages[maxAccountId] = maxValue - neededAmount;
            controllers[maxAccountId]?.text = percentages[maxAccountId]!
                .toStringAsFixed(1);
          } else {
            // No se puede hacer el cambio
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No hay suficiente porcentaje disponible'),
              ),
            );
            return;
          }
        }
      }
    }

    // Actualizar el valor
    percentages[accountId] = newValue;
    controllers[accountId]?.text = newValue.toStringAsFixed(1);
    setState(() {});
  }

  // Al terminar de escribir en el campo
  void _onFieldEditingComplete(int accountId) {
    String currentText = controllers[accountId]?.text ?? '';

    // Si está vacío, poner 0.1
    if (currentText.isEmpty) {
      _updatePercentage(accountId, 0.1);
      return;
    }

    double? parsed = double.tryParse(currentText.replaceAll(',', '.'));
    if (parsed == null) {
      // Si no es un número válido, mantener el valor anterior
      controllers[accountId]?.text = (percentages[accountId] ?? 0.1)
          .toStringAsFixed(1);
      return;
    }

    // Si es 0 o negativo, convertir a 0.1
    if (parsed <= 0) {
      _updatePercentage(accountId, 0.1);
      return;
    }

    // Si es 100 o más
    if (parsed >= 100) {
      // Poner todos los otros en 0.1
      for (int id in _ids) {
        if (id != accountId) {
          percentages[id] = 0.1;
          controllers[id]?.text = '0.1';
        }
      }
      // Este toma lo que falta para 100
      double newValue = 100.0 - ((_ids.length - 1) * 0.1);
      percentages[accountId] = newValue;
      controllers[accountId]?.text = newValue.toStringAsFixed(1);
      setState(() {});
      return;
    }

    // Si es un valor normal (entre 0.1 y 100)
    double oldValue = percentages[accountId] ?? 0;
    double difference = parsed - oldValue;

    // Si se está agregando (aumentando)
    if (difference > 0) {
      double remaining = _getRemaining();

      // Si hay suficiente restante
      if (remaining >= difference) {
        percentages[accountId] = parsed;
        controllers[accountId]?.text = parsed.toStringAsFixed(1);
        setState(() {});
        return;
      }

      // Si no hay suficiente, tomar de los otros
      double neededAmount = difference - remaining;
      Map<int, double> originalPercentages = Map.from(percentages);

      // Intentar restar de todos los otros
      List<int> otherAccounts = _ids.where((id) => id != accountId).toList();

      for (int otherId in otherAccounts) {
        double currentOtherValue = percentages[otherId] ?? 0;
        double canReduce = currentOtherValue - 0.1; // Máximo que puedo restar

        if (canReduce > 0) {
          double amountToTake = min(canReduce, neededAmount);
          percentages[otherId] = currentOtherValue - amountToTake;
          controllers[otherId]?.text = percentages[otherId]!.toStringAsFixed(1);
          neededAmount -= amountToTake;

          if (neededAmount <= 0) break;
        }
      }

      // Si aún falta, no se pudo: restaurar valores
      if (neededAmount > 0.01) {
        percentages = originalPercentages;
        for (int id in _ids) {
          controllers[id]?.text = (percentages[id] ?? 0.1).toStringAsFixed(1);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay suficiente porcentaje para este valor'),
          ),
        );
        return;
      }

      // Actualizar este
      percentages[accountId] = parsed;
      controllers[accountId]?.text = parsed.toStringAsFixed(1);
      setState(() {});
    } else {
      // Si está disminuyendo, simplemente actualizar
      _updatePercentage(accountId, parsed);
    }
  }

  /// Entrega los porcentajes. Lo que pasa después (seguir a Dinero o
  /// guardar el fondo) lo decide quien abrió esta pantalla.
  Future<void> _listo() async {
    setState(() => _guardando = true);
    await widget.onListo(Map.of(percentages));
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    double remaining = _getRemaining();
    // El botón se habilita cuando el saldo restante es 0 (o muy cercano)
    bool canContinue = remaining.abs() <= 0.1 && !_guardando;

    return Scaffold(
      appBar: AppBar(title: const Text('Repartir Fondos')),
      body: Column(
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              widget.titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Lista con sliders y campos de texto
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                double currentPercentage = percentages[item.id] ?? 0.1;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Slider para ajustar porcentaje
                      Slider(
                        value: currentPercentage.clamp(0.1, 100.0),
                        min: 0.1,
                        max: 100.0,
                        divisions: 999,
                        label: '${currentPercentage.toStringAsFixed(1)}%',
                        onChanged: (value) {
                          _updatePercentage(item.id, value);
                        },
                      ),

                      // Campo de texto para escribir manualmente
                      TextField(
                        controller: controllers[item.id],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onEditingComplete: () {
                          _onFieldEditingComplete(item.id);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Porcentaje (%)',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),

          // Saldo Restante
          Container(
            color: AppTheme.bgDarkGrey,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Restante:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  '${remaining.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: remaining.abs() <= 0.1
                        ? AppTheme.success
                        : AppTheme.danger,
                  ),
                ),
              ],
            ),
          ),

          // Botón de abajo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: canContinue ? _listo : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue
                    ? AppTheme.primary
                    : AppTheme.disabled,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
              child: Text(
                widget.textoBoton,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}