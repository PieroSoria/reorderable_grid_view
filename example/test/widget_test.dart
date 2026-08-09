import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:reorderable_grid_view_example/main.dart';

void _setSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('la app demo arranca y renderiza el grid con su botón Agregar', (
    tester,
  ) async {
    _setSurface(tester);

    await tester.pumpWidget(const ReorderableGridExampleApp());
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ReorderableGrid || widget is SliverReorderableGrid,
      ),
      findsOneWidget,
    );
    expect(find.text('Manzana'), findsOneWidget);
    expect(find.text('Sandía'), findsOneWidget);
    // Celda final personalizada visible.
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Agregar'), findsOneWidget);
  });

  testWidgets('pulsar el botón Agregar añade un nuevo elemento', (
    tester,
  ) async {
    _setSurface(tester);

    await tester.pumpWidget(const ReorderableGridExampleApp());
    await tester.pump();

    expect(find.text('Nuevo 1'), findsNothing);

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo 1'), findsOneWidget);
  });
}
