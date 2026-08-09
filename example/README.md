# reorderable_grid_view_example

App de demostración del widget [`ReorderableGrid<T>`](../).

## Ejecutar

Desde la raíz del paquete:

```sh
cd example
flutter run
```

O bien, para probarlo en el navegador:

```sh
cd example
flutter run -d chrome
```

## Qué muestra

- Un grid de 3 columnas con tarjetas reordenables mediante **presión larga y
  arrastre**, con el efecto **"empujar"** en vivo: al arrastrar, las celdas se
  apartan y se deslizan para dejar paso al elemento (activable con
  `liveReorder`).
- Un interruptor que alterna la celda final entre:
  - el **botón "Agregar" predefinido** (icono + etiqueta con borde punteado y
    colores personalizados), y
  - un **footer 100% personalizado** (`FilledButton.icon`).
- El botón "Agregar" añade un nuevo elemento al final de la lista.
- Al soltar un elemento sobre la celda final, este pasa a la última posición.

Los elementos se identifican mediante `ValueKey<_Item>(item)` (igualdad de
instancia, ya que `_Item` no sobrescribe `==`), lo que permite que Flutter
conserve el estado de cada widget cuando la cuadrícula se reordena.

## Estructura

- `lib/main.dart` — código de la app de ejemplo.
- `test/widget_test.dart` — smoke tests que verifican que la app arranca y que
  el switch alterna entre el botón predefinido y el footer personalizado.