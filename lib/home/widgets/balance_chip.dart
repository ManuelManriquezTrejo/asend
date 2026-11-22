import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/money_service.dart';
import 'package:asend/database/money_hive_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Monto del inicio: el saldo de una sola cuenta o de un elemento de
/// Dinero, a elección del usuario. Solo es para verlo: no mueve dinero.
/// Al tocarlo se elige primero el apartado (Cuentas o Dinero) y luego
/// cuál. La elección se guarda en money_settings.
class BalanceChip extends StatefulWidget {
  const BalanceChip({super.key});

  @override
  State<BalanceChip> createState() => _BalanceChipState();
}

class _BalanceChipState extends State<BalanceChip> {
  static const String _claveTipo = 'saldoInicioTipo'; // 'cuenta' o 'dinero'
  static const String _claveId = 'saldoInicioId';

  static const String _cuenta = 'cuenta';
  static const String _dinero = 'dinero';

  String _formato(double v) => '\$${v.toStringAsFixed(2)}';

  /// Nombre y saldo de lo elegido, o null si no hay nada elegido o ya
  /// fue eliminado.
  ({String nombre, double saldo})? _elegido() {
    final box = MoneyHiveService.getSettingsBox();
    final tipo = box.get(_claveTipo);
    final id = box.get(_claveId);
    if (id is! int) return null;

    if (tipo == _cuenta) {
      final c = AccountService.getAccountById(id);
      return c == null ? null : (nombre: c.name, saldo: c.balance);
    }
    if (tipo == _dinero) {
      final m = MoneyService.getById(id);
      return m == null ? null : (nombre: m.name, saldo: m.balance);
    }
    return null;
  }

  /// Paso 1: elegir el apartado. Paso 2: elegir cuál.
  Future<void> _elegir() async {
    final tipo = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text(
          '¿Qué saldo quieres ver?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        children: [
          _opcionApartado(ctx, _cuenta, 'Cuentas', Icons.account_balance),
          _opcionApartado(ctx, _dinero, 'Dinero', Icons.payments),
        ],
      ),
    );
    if (tipo == null || !mounted) return;

    // Lista del apartado elegido, cada uno con su saldo
    final opciones = tipo == _cuenta
        ? AccountService.getAllAccounts()
              .map((c) => (id: c.id, nombre: c.name, saldo: c.balance))
              .toList()
        : MoneyService.getAll()
              .map((m) => (id: m.id, nombre: m.name, saldo: m.balance))
              .toList();
    opciones.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );

    final id = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          tipo == _cuenta ? 'Cuentas' : 'Dinero',
          style: const TextStyle(color: AppTheme.textWhite),
        ),
        children: opciones.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay nada en este apartado',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                ),
              ]
            : opciones
                  .map(
                    (o) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, o.id),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ),
                          Text(
                            _formato(o.saldo),
                            style: const TextStyle(color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
    if (id == null || !mounted) return;

    final box = MoneyHiveService.getSettingsBox();
    await box.put(_claveTipo, tipo);
    await box.put(_claveId, id);
    if (mounted) setState(() {});
  }

  Widget _opcionApartado(
    BuildContext ctx,
    String valor,
    String texto,
    IconData icono,
  ) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, valor),
      child: Row(
        children: [
          Icon(icono, color: AppTheme.buttonPurple),
          const SizedBox(width: 12),
          Text(texto, style: const TextStyle(color: AppTheme.textWhite)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elegido = _elegido();

    // Solo el monto, en el color del tema. El padding agranda la zona
    // que se puede tocar sin que se vea ningún recuadro.
    return GestureDetector(
      onTap: _elegir,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        child: Text(
          elegido == null ? 'Elegir cuenta' : _formato(elegido.saldo),
          style: TextStyle(
            color: elegido == null ? AppTheme.textGrey : AppTheme.buttonPurple,
            fontSize: elegido == null ? 13 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}