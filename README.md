# reorderable_grid_view

Un widget de Flutter **`ReorderableGrid<T>`** genérico y reutilizable que
implementa un `GridView` reordenable mediante *drag and drop* nativo, **desde
cero** y **sin dependencias externas** (solo `LongPressDraggable` y
`DragTarget` del propio framework).

## Características

- Genérico: `ReorderableGrid<T>` funciona con cualquier tipo de dato.
- Reordenamiento por presión larga con *feedback* visual profesional por
  defecto (escala 1.05, opacidad 0.8 y sombra ligera).
- Celda de destino resaltada durante el arrastre.
- `onAddItemBuilder` opcional, fijo y **no arrastrable** (p. ej. un botón
  "+ Agregar") que puede devolver `null` para no mostrar celda final. Al
  soltar un elemento sobre él, este se mueve a la última posición.
- Botón "Agregar" totalmente desacoplado: sin `onAddItemBuilder` el grid no
  tiene celda final y puedes poner tu propio botón en cualquier lugar del
  layout.
- Efecto **"empujar"** en vivo (`liveReorder`): al arrastrar un elemento los
  vecinos se apartan con una animación suave y el grid se reorganiza según la
  celda sobrevolada; el reorden se confirma al soltar (se puede desactivar).
- Conserva el estado de los widgets durante el reordenamiento mediante claves
  (`itemKey` o `ValueKey<T>` por defecto) y `findChildIndexCallback`.
- Personalizable: `itemKey`, `feedbackBuilder` y `childWhenDraggingBuilder`.
- Sin paquetes de `pub.dev`.

## Semántica de índices

`onReorder(oldIndex, newIndex)` significa **"sitúa el elemento de `oldIndex`
en la posición final `newIndex`"** (índice directo, sin el desplazamiento
`newIndex -= 1` de `ReorderableListView`). Solo se invoca si los índices son
diferentes.

## Uso

```dart
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final List<String> _items = ['Manzana', 'Banana', 'Cereza', 'Durazno'];

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    setState(() {
      final String moved = _items.removeAt(oldIndex);
      _items.insert(newIndex, moved);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ReorderableGrid<String>(
          items: _items,
          onReorder: _onReorder,
          itemBuilder: (context, item, index) => Card(
            child: Center(child: Text(item)),
          ),
          onAddItemBuilder: (context) => Padding(
            padding: const EdgeInsets.all(4),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
              onPressed: () {
                // Agrega un nuevo elemento a _items.
              },
            ),
          ),
          crossAxisCount: 4,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 3 / 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }
}
```

## Parámetros

| Parámetro                   | Tipo                                            | Defecto                          |
| --------------------------- | ----------------------------------------------- | -------------------------------- |
| `items`                     | `List<T>`                                       | requerido                        |
| `itemBuilder`               | `Widget Function(BuildContext, T, int)`         | requerido                        |
| `onReorder`                 | `void Function(int oldIndex, int newIndex)`     | requerido                        |
| `onAddItemBuilder`          | `Widget Function(BuildContext)?`                | `null`                           |
| `itemKey`                   | `Key Function(T)?`                              | `ValueKey<T>(item)`              |
| `feedbackBuilder`           | `Widget Function(Widget)?`                      | *feedback* por defecto           |
| `childWhenDraggingBuilder`  | `Widget Function(Widget)?`                      | opacidad 0.2                     |
| `liveReorder`               | `bool`                                          | `true`                           |
| `crossAxisCount`            | `int`                                           | `4`                              |
| `mainAxisSpacing`           | `double`                                        | `6.0`                            |
| `crossAxisSpacing`          | `double`                                        | `6.0`                            |
| `childAspectRatio`          | `double`                                        | `3 / 4`                          |
| `shrinkWrap`                | `bool`                                          | `true`                           |
| `physics`                   | `ScrollPhysics?`                                | `NeverScrollableScrollPhysics()` |

## Notas

- El widget es *controlado*: la lista la posee el padre. Tras un arrastre se
  invoca `onReorder` y el padre debe actualizar su lista y reconstruir el grid.
- Para que Flutter conserve el estado de los widgets al reordenar, los
  elementos deben tener una identidad estable (sobrescribir `==`/`hashCode`)
  o proporcionar `itemKey`.
- Requiere un `MaterialApp` (o un `Material`) como ancestro, ya que el
  *feedback* de arrastre se dibuja en el overlay de la aplicación.

## Ejemplo ejecutable

Dentro de la carpeta `example/` hay una app de demostración completa (grid
reordenable con su celda final "Agregar" personalizada). Para ejecutarla:

```sh
cd example
flutter run
```
