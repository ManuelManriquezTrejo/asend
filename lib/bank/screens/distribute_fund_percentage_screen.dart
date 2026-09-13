import 'package:flutter/material.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/models/account.dart';
import 'package:asend/models/fund.dart';
import 'package:asend/theme/app_theme.dart';
import 'dart:math';

class DistributeFundPercentageScreen extends StatefulWidget {
  final String fundName;
  final List<int> selectedAccountIds;
  final Function onFundAdded;

  const DistributeFundPercentageScreen({
    super.key,
    required this.fundName,
    required this.selectedAccountIds,
    required this.onFundAdded,
  });

  @override
  State<DistributeFundPercentageScreen> createState() =>
      _DistributeFundPercentageScreenState();
}

class _DistributeFundPercentageScreenState
    extends State<DistributeFundPercentageScreen> {
  late Map<int, double> percentages;
  late Map<int, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    percentages = {};
    controllers = {};

    for (int accountId in widget.selectedAccountIds) {
      percentages[accountId] = 0.1;
      controllers[accountId] = TextEditingController(text: '0.1');
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

  // Obtener la cuenta con mayor porcentaje (para restar de ahí)
  int _getAccountWithMaxPercentage({int? excludeAccountId}) {
    int maxAccountId = -1;
    double maxValue = -1;

    for (int accountId in widget.selectedAccountIds) {
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
      return widget.selectedAccountIds.firstWhere(
        (id) => id != excludeAccountId,
      );
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
        // Restar de la cuenta con mayor porcentaje
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

    // Actualizar el valor
    percentages[accountId] = newValue;
    controllers[accountId]?.text = newValue.toStringAsFixed(1);
    setState(() {});
  }

  // Al perder el foco del TextField - con lógica avanzada
  void _onFieldEditingComplete(int accountId) {
    String currentText = controllers[accountId]?.text ?? '';

    // Si está vacío, poner 0.1
    if (currentText.isEmpty) {
      _updatePercentage(accountId, 0.1);
      return;
    }

    double? parsed = double.tryParse(currentText);
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
      // Poner todas las otras en 0.1
      for (int id in widget.selectedAccountIds) {
        if (id != accountId) {
          percentages[id] = 0.1;
          controllers[id]?.text = '0.1';
        }
      }
      // Esta cuenta toma lo que falta para 100
      double newValue = 100.0 - ((widget.selectedAccountIds.length - 1) * 0.1);
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

      // Si no hay suficiente, tomar de las otras cuentas
      double neededAmount = difference - remaining;
      Map<int, double> originalPercentages = Map.from(
        percentages,
      ); // Guardar copia

      // Intentar restar de todas las otras cuentas
      List<int> otherAccounts = widget.selectedAccountIds
          .where((id) => id != accountId)
          .toList();

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

      // Si aún falta, verificar si se pudo completar
      if (neededAmount > 0.01) {
        // No se pudo, restaurar valores
        percentages = originalPercentages;
        for (int id in widget.selectedAccountIds) {
          controllers[id]?.text = (percentages[id] ?? 0.1).toStringAsFixed(1);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay suficiente porcentaje para este valor'),
          ),
        );
        return;
      }

      // Actualizar esta cuenta
      percentages[accountId] = parsed;
      controllers[accountId]?.text = parsed.toStringAsFixed(1);
      setState(() {});
    } else {
      // Si está disminuyendo, simplemente actualizar
      _updatePercentage(accountId, parsed);
    }
  }

  // Guardar el fondo
  void _saveFund() async {
    try {
      // Crear el fondo
      await FundService.addFund(name: widget.fundName);

      // Obtener el ID del fondo recién creado
      List<Fund> allFunds = FundService.getAllFunds();

      // Buscar el ID más alto, no la última posición de la lista
      int fundId = allFunds.map((f) => f.id).reduce(max);

      // Guardar las relaciones fondo-cuenta
      for (int accountId in widget.selectedAccountIds) {
        double percentage = percentages[accountId] ?? 0.1;
        await FundService.addFundAccount(
          fundId: fundId,
          accountId: accountId,
          percentage: percentage,
        );
      }

      // Notificar que se creó el fondo
      widget.onFundAdded();

      // Verificar que el widget aún está montado
      if (!mounted) return;

      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.bgDarkGrey,
            title: Text(
              'El fondo "${widget.fundName}" se guardó correctamente',
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'La distribución de porcentajes se ha aplicado correctamente.',
              style: TextStyle(color: AppTheme.textGrey),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Cierra el diálogo
                  Navigator.pop(context);
                  // Pop 1: DistributeFundPercentageScreen
                  Navigator.pop(context);
                  // Pop 2: SelectAccountsForFundScreen
                  Navigator.pop(context);
                  // Pop 3: AddFundNameScreen
                  Navigator.pop(context);
                  // Ya estás en BankScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buttonPurple,
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(color: AppTheme.textWhite),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double remaining = _getRemaining();
    // El botón se habilita cuando saldo restante es 0 (o muy cercano)
    bool canContinue = remaining.abs() <= 0.1;

    return Scaffold(
      appBar: AppBar(title: const Text('Repartir Fondos')),
      body: Column(
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Distribuye "${widget.fundName}" entre las cuentas',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.buttonPurple,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Lista de cuentas con sliders y campos de texto
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedAccountIds.length,
              itemBuilder: (context, index) {
                int accountId = widget.selectedAccountIds[index];
                Account? account = AccountService.getAccountById(accountId);
                double currentPercentage = percentages[accountId] ?? 0.1;

                if (account == null) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre de la cuenta
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Slider para ajustar porcentaje
                      Slider(
                        value: currentPercentage,
                        min: 0.1,
                        max: 100.0,
                        divisions: 999,
                        label: '${currentPercentage.toStringAsFixed(1)}%',
                        onChanged: (value) {
                          _updatePercentage(accountId, value);
                        },
                      ),

                      // Campo de texto para escribir manualmente
                      TextField(
                        controller: controllers[accountId],
                        keyboardType: TextInputType.number,
                        onEditingComplete: () {
                          _onFieldEditingComplete(accountId);
                        },
                        onChanged: (value) {
                          // No hacer nada mientras se escribe
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
                    color: canContinue ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              ],
            ),
          ),

          // Botón "Guardar Fondo"
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: canContinue ? _saveFund : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue
                    ? AppTheme.buttonPurple
                    : AppTheme.disabled,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
              child: const Text(
                'Guardar Fondo',
                style: TextStyle(fontSize: 16, color: AppTheme.textWhite),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
