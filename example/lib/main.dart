import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

void main() {
  runApp(const ReorderableGridExampleApp());
}

/// App de ejemplo que demuestra el uso de [ReorderableGrid].
class ReorderableGridExampleApp extends StatelessWidget {
  const ReorderableGridExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReorderableGrid Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: const Color(0xFFF7F9FA),
      ),
      home: const _HomePage(),
    );
  }
}

/// Elemento genérico de la demo.
class _Item {
  const _Item(this.label, this.color);

  final String label;
  final Color color;
}

/// Paleta usada para los elementos iniciales y los nuevos.
const List<Color> _palette = [
  Color(0xFFEF5350),
  Color(0xFFAB47BC),
  Color(0xFF5C6BC0),
  Color(0xFF42A5F5),
  Color(0xFF26A69A),
  Color(0xFF66BB6A),
  Color(0xFFFFCA28),
  Color(0xFFFF7043),
];

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  /// La lista mutable que posee el estado. Se muta en cada reordenamiento y
  /// adición; no debe ser `const`.
  final List<_Item> _items = [
    const _Item('Manzana', Color(0xFFEF5350)),
    const _Item('Banana', Color(0xFFFFCA28)),
    const _Item('Kiwi', Color(0xFF66BB6A)),
    const _Item('Limón', Color(0xFF26A69A)),
    const _Item('Pera', Color(0xFFAB47BC)),
    const _Item('Uva', Color(0xFF5C6BC0)),
    const _Item('Sandía', Color(0xFF42A5F5)),
  ];

  /// Contador para etiquetar los elementos añadidos en tiempo de ejecución.
  int _addCounter = 0;

  /// Semántica de índices del widget: mover el elemento de [oldIndex] a la
  /// posición final [newIndex].
  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    setState(() {
      final _Item item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  /// Añade un nuevo elemento al final de la lista.
  void _addItem() {
    setState(() {
      _addCounter += 1;
      _items.add(
        _Item('Nuevo $_addCounter', _palette[_addCounter % _palette.length]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReorderableGrid'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Mantén pulsada una tarjeta y arrástrala a otra posición para '
                'reordenar la lista.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverReorderableGrid(
              itemCount: _items.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) =>
                  _ItemCard(item: _items[index], index: index),
              // En lugar de la clave por defecto (basada en la posición),
              // seguimos el elemento usando su identidad: así, si las tarjetas
              // tuvieran widgets con estado (p. ej. un TextField), el estado
              // viajaría con la tarjeta y no se quedaría en la celda.
              itemKey: (index) => ObjectKey(_items[index]),
              // Celda final opcional y no arrastrable. El builder puede
              // devolver `null` para no mostrar ninguna celda (y poner el
              // botón "Agregar" fuera del grid, en tu propio layout). Soltar
              // un elemento sobre ella lo mueve a la última posición.
              onAddItemBuilder: (context) => Padding(
                padding: const EdgeInsets.all(2),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: _addItem,
                ),
              ),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3 / 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta visual de cada elemento.
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.index});

  final _Item item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 8,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: Colors.white24,
              child: Text(
                '$index',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
