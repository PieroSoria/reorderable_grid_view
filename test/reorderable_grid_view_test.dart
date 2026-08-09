import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reorderable_grid_view/reorderable_grid_view.dart';

/// Harness controlado que posee la lista y aplica la semántica de índices del
/// widget: "mover el elemento de [oldIndex] a la posición [newIndex]".
class _Harness extends StatefulWidget {
  const _Harness({
    required this.initialItems,
    this.showFooter = false,
    this.itemKey,
    this.liveReorder = true,
  });

  final List<String> initialItems;
  final bool showFooter;
  final Key Function(String item)? itemKey;
  final bool liveReorder;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late List<String> items = List.of(widget.initialItems);
  final List<List<int>> moves = [];

  @override
  Widget build(BuildContext context) {
    return ReorderableGrid<String>(
      items: items,
      itemKey: widget.itemKey,
      onReorder: (oldIndex, newIndex) {
        moves.add([oldIndex, newIndex]);
        if (oldIndex == newIndex) return;
        setState(() {
          final String moved = items.removeAt(oldIndex);
          items.insert(newIndex, moved);
        });
      },
      itemBuilder: (context, item, index) => Container(
        color: index.isEven ? Colors.blueGrey : Colors.teal,
        alignment: Alignment.center,
        child: Text(item),
      ),
      onAddItemBuilder: widget.showFooter
          ? (context) => const ColoredBox(
              color: Colors.amber,
              child: Center(child: Text('ADD')),
            )
          : null,
      liveReorder: widget.liveReorder,
      crossAxisCount: 2,
      childAspectRatio: 1,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
}

/// Configura la superficie de la prueba para que quepan varias filas del grid
/// sin errores de overflow (el grid no se desplaza por defecto).
void _setSurfaceSize(
  WidgetTester tester, {
  double width = 800,
  double height = 1300,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Simula un arrastre con presión larga desde [from] hasta [to].
Future<void> _longPressDrag(WidgetTester tester, Offset from, Offset to) async {
  final TestGesture gesture = await tester.startGesture(from);
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 150));
  await gesture.moveTo(to);
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.up();
  await tester.pumpAndSettle();
}

Widget _wrap(Widget grid) => MaterialApp(
  home: Scaffold(body: Center(child: grid)),
);

void main() {
  testWidgets('renderiza los elementos en orden', (tester) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(const _Harness(initialItems: ['A', 'B', 'C', 'D'])),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);

    final Offset a = tester.getTopLeft(find.text('A'));
    final Offset b = tester.getTopLeft(find.text('B'));
    final Offset c = tester.getTopLeft(find.text('C'));
    final Offset d = tester.getTopLeft(find.text('D'));

    // A y B comparten la primera fila, C y D la segunda.
    expect(a.dy, equals(b.dy));
    expect(c.dy, equals(d.dy));
    expect(c.dy, greaterThan(a.dy));
    expect(a.dx, lessThan(b.dx));
  });

  testWidgets('itemBuilder recibe el item y el índice correctos', (
    tester,
  ) async {
    _setSurfaceSize(tester);
    final List<String> seen = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ReorderableGrid<String>(
              items: const ['A', 'B'],
              onReorder: (oldIndex, newIndex) {},
              itemBuilder: (context, item, index) {
                seen.add('$item@$index');
                return Container(
                  alignment: Alignment.center,
                  child: Text('$item$index'),
                );
              },
              crossAxisCount: 2,
              childAspectRatio: 1,
            ),
          ),
        ),
      ),
    );

    expect(seen, ['A@0', 'B@1']);
    expect(find.text('A0'), findsOneWidget);
    expect(find.text('B1'), findsOneWidget);
  });

  testWidgets('el footer aparece justo después del último elemento', (
    tester,
  ) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(
        const _Harness(initialItems: ['A', 'B', 'C', 'D'], showFooter: true),
      ),
    );

    final Offset d = tester.getTopLeft(find.text('D'));
    final Offset footer = tester.getTopLeft(find.text('ADD'));

    expect(find.text('ADD'), findsOneWidget);
    expect(footer.dy, greaterThan(d.dy));
  });

  testWidgets('arrastrar el primer elemento sobre el último reordena', (
    tester,
  ) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(const _Harness(initialItems: ['A', 'B', 'C', 'D'])),
    );

    await _longPressDrag(
      tester,
      tester.getCenter(find.text('A')),
      tester.getCenter(find.text('D')),
    );

    final _HarnessState state = tester.state<_HarnessState>(
      find.byType(_Harness),
    );
    expect(state.moves, [
      [0, 3],
    ]);
    expect(state.items, ['B', 'C', 'D', 'A']);

    // A debe quedar en la última posición, en la segunda fila.
    final Offset a = tester.getTopLeft(find.text('A'));
    expect(a.dy, greaterThan(tester.getTopLeft(find.text('B')).dy));
  });

  testWidgets('soltar sobre la misma celda no invoca onReorder', (
    tester,
  ) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(const _Harness(initialItems: ['A', 'B', 'C', 'D'])),
    );

    final Offset center = tester.getCenter(find.text('A'));
    await _longPressDrag(tester, center, center + const Offset(2, 2));

    final _HarnessState state = tester.state<_HarnessState>(
      find.byType(_Harness),
    );
    expect(state.moves, isEmpty);
    expect(state.items, ['A', 'B', 'C', 'D']);
  });

  testWidgets('soltar sobre el footer mueve el elemento a la última posición', (
    tester,
  ) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(
        const _Harness(initialItems: ['A', 'B', 'C', 'D'], showFooter: true),
      ),
    );

    await _longPressDrag(
      tester,
      tester.getCenter(find.text('B')),
      tester.getCenter(find.text('ADD')),
    );

    final _HarnessState state = tester.state<_HarnessState>(
      find.byType(_Harness),
    );
    // items.length - 1 == 3
    expect(state.moves, [
      [1, 3],
    ]);
    expect(state.items, ['A', 'C', 'D', 'B']);
  });

  testWidgets('el footer no es arrastrable', (tester) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(
        const _Harness(initialItems: ['A', 'B', 'C', 'D'], showFooter: true),
      ),
    );

    await _longPressDrag(
      tester,
      tester.getCenter(find.text('ADD')),
      tester.getCenter(find.text('ADD')) - const Offset(500, 0),
    );

    final _HarnessState state = tester.state<_HarnessState>(
      find.byType(_Harness),
    );
    expect(state.moves, isEmpty);
    expect(state.items, ['A', 'B', 'C', 'D']);
  });

  testWidgets('respeta un itemKey proporcionado por el usuario', (
    tester,
  ) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(
        _Harness(
          initialItems: const ['A', 'B', 'C', 'D'],
          itemKey: (item) => ValueKey('cell_$item'),
        ),
      ),
    );

    await _longPressDrag(
      tester,
      tester.getCenter(find.text('A')),
      tester.getCenter(find.text('C')),
    );

    final _HarnessState state = tester.state<_HarnessState>(
      find.byType(_Harness),
    );
    expect(state.moves, [
      [0, 2],
    ]);
    expect(state.items, ['B', 'C', 'A', 'D']);
  });

  testWidgets('sin onAddItemBuilder no se añade celda final', (tester) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(const _Harness(initialItems: ['A', 'B', 'C', 'D'])),
    );

    // No hay celda final personalizada: solo los 4 elementos.
    expect(find.text('ADD'), findsNothing);

    // El grid ocupa solo 2 filas: la última fila contiene a C y D.
    expect(
      tester.getTopLeft(find.text('D')).dy,
      tester.getTopLeft(find.text('C')).dy,
    );
  });

  testWidgets('onAddItemBuilder que devuelve null no añade celda final', (
    tester,
  ) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(
        ReorderableGrid<String>(
          items: const ['A', 'B', 'C', 'D'],
          onReorder: (oldIndex, newIndex) {},
          itemBuilder: (context, item, index) =>
              Container(alignment: Alignment.center, child: Text(item)),
          onAddItemBuilder: (context) => null,
          crossAxisCount: 2,
          childAspectRatio: 1,
        ),
      ),
    );

    // El builder devuelve null: no hay ninguna celda final.
    expect(find.text('ADD'), findsNothing);
  });

  testWidgets('al volver a la celda de origen el empuje se revierte', (
    tester,
  ) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(const _Harness(initialItems: ['A', 'B', 'C', 'D'])),
    );

    final Offset originA = tester.getCenter(find.text('A'));
    final Offset originB = tester.getCenter(find.text('B'));
    final Offset originC = tester.getCenter(find.text('C'));
    final Offset originD = tester.getCenter(find.text('D'));

    final TestGesture gesture = await tester.startGesture(originA);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 150));

    // Empuja A hasta el final (posicion 3).
    await gesture.moveTo(originD);
    await tester.pumpAndSettle();

    // La vista previa esta empujada: B ocupo la celda original de A.
    expect((tester.getCenter(find.text('B')) - originA).distance, lessThan(5));

    // Devuelve el dedo a la celda de origen (la del propio elemento A).
    await gesture.moveTo(originA);
    await tester.pumpAndSettle();

    // El empuje se deshace: B, C y D vuelven a sus posiciones originales.
    expect((tester.getCenter(find.text('B')) - originB).distance, lessThan(5));
    expect((tester.getCenter(find.text('C')) - originC).distance, lessThan(5));
    expect((tester.getCenter(find.text('D')) - originD).distance, lessThan(5));

    // La lista del padre sigue intacta durante el arrastre.
    final _HarnessState state = tester.state<_HarnessState>(
      find.byType(_Harness),
    );
    expect(state.items, ['A', 'B', 'C', 'D']);
    expect(state.moves, isEmpty);

    // Soltar sobre la celda de origen no reordena.
    await gesture.up();
    await tester.pumpAndSettle();

    expect(state.items, ['A', 'B', 'C', 'D']);
    expect(state.moves, isEmpty);
  });

  testWidgets('con liveReorder la vista se reordena en vivo durante el arrastre', (
    tester,
  ) async {
    _setSurfaceSize(tester);
    await tester.pumpWidget(
      _wrap(const _Harness(initialItems: ['A', 'B', 'C', 'D'])),
    );

    final Offset originalA = tester.getCenter(find.text('A'));

    final TestGesture gesture = await tester.startGesture(originalA);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 150));
    // Apunta sobre la celda de D (índice 3). Con liveReorder, A se desplaza a
    // la última posición y los vecinos "empujan": B y C pasan a la primera
    // fila, todo sin soltar el dedo.
    await gesture.moveTo(tester.getCenter(find.text('D')));
    // Deja que el reorden en vivo se aplique y la animación de empuje termine.
    await tester.pumpAndSettle();

    // En el estado original B y C estaban en filas distintas; tras "empujar",
    // B y C comparten la primera fila.
    final Offset b = tester.getCenter(find.text('B'));
    final Offset c = tester.getCenter(find.text('C'));
    expect(b.dy, equals(c.dy));
    expect(b.dx, lessThan(c.dx));

    // B ahora ocupa la celda original de A.
    expect((b - originalA).distance, lessThan(5));

    // La lista del padre NO se ha modificado todavía (solo es una vista previa).
    final _HarnessState state = tester.state<_HarnessState>(
      find.byType(_Harness),
    );
    expect(state.items, ['A', 'B', 'C', 'D']);
    expect(state.moves, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    // Al soltar se confirma el reordenamiento.
    expect(state.moves, [
      [0, 3],
    ]);
    expect(state.items, ['B', 'C', 'D', 'A']);
  });

  testWidgets(
    'con liveReorder desactivado los vecinos no cambian en el arrastre',
    (tester) async {
      _setSurfaceSize(tester);
      await tester.pumpWidget(
        _wrap(
          const _Harness(
            initialItems: ['A', 'B', 'C', 'D'],
            liveReorder: false,
          ),
        ),
      );

      await _longPressDrag(
        tester,
        tester.getCenter(find.text('A')),
        tester.getCenter(find.text('D')),
      );

      final _HarnessState state = tester.state<_HarnessState>(
        find.byType(_Harness),
      );
      expect(state.moves, [
        [0, 3],
      ]);
      expect(state.items, ['B', 'C', 'D', 'A']);
    },
  );
}
