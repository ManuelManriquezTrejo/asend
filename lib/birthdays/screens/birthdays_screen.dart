import 'package:asend/birthdays/services/birthday_service.dart';
import 'package:asend/models/birthday.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BirthdaysScreen extends StatefulWidget {
  const BirthdaysScreen({super.key});

  @override
  State<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends State<BirthdaysScreen> {
  static const List<String> _mesesCortos = [
    '',
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
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

  // ─────────────────────────────────────────────
  // SELECTORES REUTILIZABLES
  // ─────────────────────────────────────────────

  /// Lista alfabética de personas. Devuelve la elegida o null.
  Future<Birthday?> _elegirPersona(String titulo) {
    final personas = BirthdayService.getAlfabetico();

    return showDialog<Birthday>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          titulo,
          style: const TextStyle(color: AppTheme.textWhite, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: personas
                .map(
                  (p) => ListTile(
                    title: Text(
                      p.nombre,
                      style: const TextStyle(color: AppTheme.textWhite),
                    ),
                    trailing: Text(
                      '${p.dia.toString().padLeft(2, '0')} '
                      '${_mesesCortos[p.mes]}',
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, p),
                  ),
                )
                .toList(),
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
        ],
      ),
    );
  }

  /// Campo de texto simple. Devuelve el texto o null si cancela.
  Future<String?> _pedirTexto({
    required String titulo,
    required String etiqueta,
    String inicial = '',
    bool permitirVacio = false,
    int maxLineas = 1,
  }) async {
    final controller = TextEditingController(text: inicial);

    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo, style: const TextStyle(color: AppTheme.textWhite)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLineas,
          style: const TextStyle(color: AppTheme.textWhite),
          decoration: InputDecoration(
            labelText: etiqueta,
            labelStyle: const TextStyle(color: AppTheme.textHint),
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
              final texto = controller.text.trim();
              if (texto.isEmpty && !permitirVacio) return;
              Navigator.pop(ctx, texto);
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppTheme.buttonPurple),
            ),
          ),
        ],
      ),
    );

    // El TextField sigue usando el controlador durante la animación
    // de cierre; liberarlo antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    controller.dispose();

    return resultado;
  }

  /// Calendario para elegir día y mes. El año que salga se ignora.
  Future<DateTime?> _pedirFecha({int? dia, int? mes}) {
    final ahora = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: DateTime(ahora.year, mes ?? ahora.month, dia ?? ahora.day),
      firstDate: DateTime(ahora.year, 1, 1),
      lastDate: DateTime(ahora.year, 12, 31),
      helpText: 'Elige día y mes',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.buttonPurple,
            surface: AppTheme.bgDarkGrey,
            onSurface: AppTheme.textWhite,
          ),
        ),
        child: child!,
      ),
    );
  }

  /// Rueda de años con la edad calculada al lado, actualizándose al girar.
  Future<int?> _pedirAnio(Birthday persona) async {    final anioMax = DateTime.now().year;
    const anioMin = 1920;

    // Arranca en el año registrado, o en 2000 si no tiene
    int seleccionado = persona.anio ?? 2000;

    final controller = FixedExtentScrollController(
      initialItem: seleccionado - anioMin,
    );

    final resultado = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final edad = BirthdayService.edadParaAnio(
            seleccionado,
            persona.dia,
            persona.mes,
          );

          return AlertDialog(
            title: const Text(
              'Año de nacimiento',
              style: TextStyle(color: AppTheme.textWhite),
            ),
            content: SizedBox(
              height: 180,
              width: double.maxFinite,
              child: Row(
                children: [
                  // La rueda
                  Expanded(
                    child: Stack(
                      children: [
                        // Marca del centro
                        Center(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.buttonPurple.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        ListWheelScrollView.useDelegate(
                          controller: controller,
                          itemExtent: 40,
                          perspective: 0.005,
                          diameterRatio: 1.6,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) => setDialogState(() {
                            seleccionado = anioMin + i;
                          }),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: anioMax - anioMin + 1,
                            builder: (ctx, i) {
                              final anio = anioMin + i;
                              final activo = anio == seleccionado;
                              return Center(
                                child: Text(
                                  '$anio',
                                  style: TextStyle(
                                    color: activo
                                        ? AppTheme.textWhite
                                        : AppTheme.textHint,
                                    fontSize: activo ? 22 : 17,
                                    fontWeight: activo
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // La edad, alineada al centro de la rueda
                  Expanded(
                    child: Center(
                      child: Text(
                        '$edad años',
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                onPressed: () => Navigator.pop(ctx, seleccionado),
                child: const Text(
                  'Guardar',
                  style: TextStyle(color: AppTheme.buttonPurple),
                ),
              ),
            ],
          );
        },
      ),
    );

    // La rueda sigue usando el controlador durante la animación
    // de cierre; liberarlo antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    controller.dispose();

    return resultado;
  }
  // ─────────────────────────────────────────────
  // ACCIONES
  // ─────────────────────────────────────────────

  Future<void> _agregar() async {
    final nombre = await _pedirTexto(
      titulo: 'Nuevo cumpleaños',
      etiqueta: 'Nombre',
    );
    if (nombre == null || !mounted) return;

    final fecha = await _pedirFecha();
    if (fecha == null || !mounted) return;

    await BirthdayService.agregar(
      nombre: nombre,
      dia: fecha.day,
      mes: fecha.month,
    );

    if (!mounted) return;
    setState(() {});
    _aviso('$nombre agregado', esError: false);
  }

  Future<void> _editar() async {
    final personas = BirthdayService.getAlfabetico();
    if (personas.isEmpty) {
      _aviso('No hay cumpleaños registrados');
      return;
    }

    final persona = await _elegirPersona('¿A quién quieres editar?');
    if (persona == null || !mounted) return;

    final campo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          persona.nombre,
          style: const TextStyle(color: AppTheme.textWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.buttonPurple),
              title: const Text(
                'Nombre',
                style: TextStyle(color: AppTheme.textWhite),
              ),
              onTap: () => Navigator.pop(ctx, 'nombre'),
            ),
            ListTile(
              leading: const Icon(Icons.event, color: AppTheme.buttonPurple),
              title: const Text(
                'Fecha',
                style: TextStyle(color: AppTheme.textWhite),
              ),
              onTap: () => Navigator.pop(ctx, 'fecha'),
            ),
            ListTile(
              leading: const Icon(Icons.cake, color: AppTheme.buttonPurple),
              title: const Text(
                'Año',
                style: TextStyle(color: AppTheme.textWhite),
              ),
              onTap: () => Navigator.pop(ctx, 'anio'),
            ),
            ListTile(
              leading: const Icon(Icons.notes, color: AppTheme.buttonPurple),
              title: const Text(
                'Nota',
                style: TextStyle(color: AppTheme.textWhite),
              ),
              onTap: () => Navigator.pop(ctx, 'nota'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );
    if (campo == null || !mounted) return;

    switch (campo) {
      case 'nombre':
        final nombre = await _pedirTexto(
          titulo: 'Editar nombre',
          etiqueta: 'Nombre',
          inicial: persona.nombre,
        );
        if (nombre == null || !mounted) return;
        await BirthdayService.editar(birthdayId: persona.id, nombre: nombre);
        break;

      case 'fecha':
        final fecha = await _pedirFecha(dia: persona.dia, mes: persona.mes);
        if (fecha == null || !mounted) return;
        await BirthdayService.editar(
          birthdayId: persona.id,
          dia: fecha.day,
          mes: fecha.month,
        );
        break;

      case 'anio':
        final anio = await _pedirAnio(persona);
        if (anio == null || !mounted) return;
        await BirthdayService.editar(birthdayId: persona.id, anio: anio);
        break;

      case 'nota':
        final nota = await _pedirTexto(
          titulo: 'Nota de ${persona.nombre}',
          etiqueta: 'Nota',
          inicial: persona.nota ?? '',
          permitirVacio: true,
          maxLineas: 4,
        );
        if (nota == null || !mounted) return;
        await BirthdayService.editar(birthdayId: persona.id, nota: nota);
        break;
    }

    if (!mounted) return;
    setState(() {});
    _aviso('Actualizado', esError: false);
  }

  Future<void> _eliminar() async {
    final personas = BirthdayService.getAlfabetico();
    if (personas.isEmpty) {
      _aviso('No hay cumpleaños registrados');
      return;
    }

    final persona = await _elegirPersona('¿A quién quieres eliminar?');
    if (persona == null || !mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Eliminar cumpleaños',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '¿Eliminar a ${persona.nombre}?',
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

    await BirthdayService.eliminar(persona.id);
    if (!mounted) return;
    setState(() {});
    _aviso('${persona.nombre} eliminado', esError: false);
  }

  /// Tocar una fila abre su nota en modo lectura y edición rápida.
  Future<void> _verNota(Birthday persona) async {
    final nota = await _pedirTexto(
      titulo: persona.nombre,
      etiqueta: 'Nota',
      inicial: persona.nota ?? '',
      permitirVacio: true,
      maxLineas: 4,
    );
    if (nota == null || !mounted) return;

    await BirthdayService.editar(birthdayId: persona.id, nota: nota);
    if (!mounted) return;
    setState(() {});
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cumples = BirthdayService.getTodos();

    return Scaffold(
      appBar: AppBar(title: const Text('Cumpleaños'), centerTitle: true),
      body: Column(
        children: [
          // Encabezado de columnas, fijo
          if (cumples.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Fecha',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Nombre',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      'Edad',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

          // Lo único que se mueve con el scroll
          Expanded(
            child: cumples.isEmpty
                ? const Center(
                    child: Text(
                      'Aún no hay cumpleaños registrados',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 15),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    children: cumples.map((b) {
                      final edad = BirthdayService.edadActual(b);
                      final hoy = BirthdayService.esHoy(b);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgDarkGrey,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              // El de hoy se resalta
                              color: hoy
                                  ? AppTheme.success
                                  : AppTheme.buttonPurple.withValues(
                                      alpha: 0.3,
                                    ),
                              width: hoy ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _verNota(b),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  // Fecha
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${b.dia.toString().padLeft(2, '0')} '
                                      '${_mesesCortos[b.mes]}',
                                      style: TextStyle(
                                        color: hoy
                                            ? AppTheme.success
                                            : AppTheme.textGrey,
                                        fontSize: 14,
                                        fontWeight: hoy
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  // Nombre
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            b.nombre,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppTheme.textWhite,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (b.nota != null) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.notes,
                                            color: AppTheme.textHint,
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Edad
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      edad == null ? '—' : '$edad',
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        color: edad == null
                                            ? AppTheme.textHint
                                            : AppTheme.textWhite,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Botones fijos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: _agregar,
                    child: const Text('Agregar'),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: _editar,
                    child: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: _eliminar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                    ),
                    child: const Text('Eliminar'),
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
