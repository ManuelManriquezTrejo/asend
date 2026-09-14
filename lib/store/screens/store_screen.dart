import 'package:asend/goals/screens/goals_screen.dart';
import 'package:asend/models/purchase.dart';
import 'package:asend/store/services/purchase_service.dart';
import 'package:asend/store/screens/purchase_history_screen.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  void _aviso(String mensaje, {bool esError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  /// Formulario de compra. Sirve para agregar y para editar.
  /// Devuelve (nombre, precio, nota) o null si cancela.
  Future<({String nombre, int precio, String? nota})?> _formulario({
    required String titulo,
    Purchase? compra,
  }) async {
    final nombreCtrl = TextEditingController(text: compra?.nombre ?? '');
    final precioCtrl = TextEditingController(
      text: compra == null ? '' : '${compra.precio}',
    );
    final notaCtrl = TextEditingController(text: compra?.nota ?? '');

    final saldo = PurchaseService.getSaldoCuenta();

    final resultado =
        await showDialog<({String nombre, int precio, String? nota})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo, style: const TextStyle(color: AppTheme.textWhite)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (saldo != null) ...[
                Text(
                  'Disponible: ${saldo.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: nombreCtrl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(color: AppTheme.textHint),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  labelStyle: TextStyle(color: AppTheme.textHint),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notaCtrl,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  labelStyle: TextStyle(color: AppTheme.textHint),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              final precio = int.tryParse(precioCtrl.text.trim());
              final nota = notaCtrl.text.trim();

              // Nombre y precio son obligatorios
              if (nombre.isEmpty || precio == null || precio <= 0) return;

              Navigator.pop(ctx, (
                nombre: nombre,
                precio: precio,
                nota: nota.isEmpty ? null : nota,
              ));
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppTheme.buttonPurple),
            ),
          ),
        ],
      ),
    );

    // Los TextField siguen usando los controladores durante la animación
    // de cierre; liberarlos antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    nombreCtrl.dispose();
    precioCtrl.dispose();
    notaCtrl.dispose();

    return resultado;
  }

  Future<void> _agregarCompra() async {
    final datos = await _formulario(titulo: 'Registrar compra');
    if (datos == null || !mounted) return;

    final error = await PurchaseService.agregar(
      nombre: datos.nombre,
      precio: datos.precio,
      nota: datos.nota,
    );

    if (!mounted) return;
    setState(() {});

    if (error != null) {
      _aviso(error);
    } else {
      _aviso('Compra registrada', esError: false);
    }
  }

  Future<void> _editarCompra(Purchase compra) async {
    final datos = await _formulario(titulo: 'Editar compra', compra: compra);
    if (datos == null || !mounted) return;

    final error = await PurchaseService.editar(
      purchaseId: compra.id,
      nombre: datos.nombre,
      precio: datos.precio,
      nota: datos.nota,
    );

    if (!mounted) return;
    setState(() {});

    if (error != null) {
      _aviso(error);
    } else {
      _aviso('Compra actualizada', esError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compras = PurchaseService.getDelMesActual();
    final total = PurchaseService.getTotalDelMesActual();

    return Scaffold(
      appBar: AppBar(title: const Text('Tienda'), centerTitle: true),
      body: Column(
        children: [
          // Lo único que se mueve con el scroll
          Expanded(
            child: compras.isEmpty
                ? const Center(
                    child: Text(
                      'Sin compras este mes',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 15),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: compras.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: AppTheme.bgDarkGrey,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppTheme.buttonPurple.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: ListTile(
                            onTap: () => _editarCompra(c),
                            title: Text(
                              c.nombre,
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: c.nota == null
                                ? null
                                : Text(
                                    c.nota!,
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                            trailing: Text(
                              '${c.precio}',
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Total del mes, fijo abajo a la derecha
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Total del mes: ',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                ),
                Text(
                  '$total',
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Barra de botones fija: 25% / 50% / 25% con márgenes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Expanded(
                  flex: 25,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GoalsScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text(
                      'Metas',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 50,
                  child: ElevatedButton(
                    onPressed: _agregarCompra,
                    child: const Text('Registrar compra'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 25,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PurchaseHistoryScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text(
                      'Historial',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
