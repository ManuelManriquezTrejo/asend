import 'package:asend/models/purchase.dart';
import 'package:asend/store/services/purchase_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  // Meses desplegados, identificados como "anio-mes"
  final Set<String> _abiertos = {};

  static const List<String> _nombresMes = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  void _aviso(String mensaje, {bool esError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  Future<void> _eliminarCompra(Purchase compra) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Eliminar compra',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '"${compra.nombre}" por ${compra.precio}.\n\n'
          'El dinero regresará a la cuenta.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final error = await PurchaseService.eliminar(compra.id);
    if (!mounted) return;
    setState(() {});

    if (error != null) {
      _aviso(error);
    } else {
      _aviso('Compra eliminada, dinero devuelto', esError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meses = PurchaseService.getMeses();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: meses.map((m) {
          final clave = '${m.anio}-${m.mes}';
          final abierto = _abiertos.contains(clave);
          final compras = abierto
              ? PurchaseService.getDelMes(m.anio, m.mes)
              : <Purchase>[];

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
              child: Column(
                children: [
                  // Fila del mes: nombre, total y botón ver
                  ListTile(
                    title: Text(
                      '${_nombresMes[m.mes]} ${m.anio}',
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${m.total}',
                          style: TextStyle(
                            color: m.total == 0
                                ? AppTheme.textHint
                                : AppTheme.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => setState(() {
                            if (abierto) {
                              _abiertos.remove(clave);
                            } else {
                              _abiertos.add(clave);
                            }
                          }),
                          child: Text(
                            abierto ? 'Ocultar' : 'Ver',
                            style: const TextStyle(
                              color: AppTheme.buttonPurple,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Desglose del mes
                  if (abierto) ...[
                    const Divider(height: 1, color: AppTheme.disabled),
                    if (compras.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Sin compras este mes',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      ...compras.map(
                        (c) => ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(
                            left: 20,
                            right: 8,
                          ),
                          title: Text(
                            c.nombre,
                            style: const TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${c.fecha.day.toString().padLeft(2, '0')}/'
                            '${c.fecha.month.toString().padLeft(2, '0')}/'
                            '${c.fecha.year}'
                            '${c.nota == null ? '' : ' · ${c.nota}'}',
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 11,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${c.precio}',
                                style: const TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppTheme.danger,
                                  size: 20,
                                ),
                                onPressed: () => _eliminarCompra(c),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
