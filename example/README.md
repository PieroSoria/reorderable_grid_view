# reorderable_grid_view_example

App de demostración del widget [`ReorderableGrid`](../).

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
- La variante **sliver** (`SliverReorderableGrid`) dentro de un
  `CustomScrollView`.
- Una **celda final opcional** (`onAddItemBuilder`) con un botón "Agregar"
  personalizado que añade un elemento al final de la lista. Al soltar un
  elemento sobre esa celda, este pasa a la última posición.

Los elementos se identifican mediante `itemKey: (index) => ObjectKey(_items[index])`
(identidad de instancia, ya que `_Item` no sobrescribe `==`), lo que permite que
el estado siga al elemento — y no a la celda — cuando la cuadrícula se reordena.

## Estructura

- `lib/main.dart` — código de la app de ejemplo.
- `test/widget_test.dart` — smoke tests que verifican que la app arranca y que
  el botón "Agregar" añade un nuevo elemento.