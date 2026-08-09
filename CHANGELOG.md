## 0.1.0

* API por índices estilo `ListView.builder`: `itemCount` + `itemBuilder` +
  `itemKey(index)` (se elimina el genérico `T` y el parámetro `items`).
* La clave por defecto pasa a ser `ValueKey<int>(index)` (el estado viaja con
  la celda); usa `itemKey` para que el estado siga al elemento.

## 0.0.1

* Widget `ReorderableGrid<T>` reordenable con drag & drop nativo.
* Efecto "empujar" en vivo durante el arrastre (`liveReorder`, animado).
* Celda final opcional `onAddItemBuilder`, no arrastrable y que puede devolver
  `null` para no mostrarla (con DragTarget hacia la última posición).
* Variante sliver `SliverReorderableGrid` para usar dentro de un
  `CustomScrollView` (misma lógica de arrastre y empuje).
* Botón "Agregar" desacoplado: sin `onAddItemBuilder` no hay celda final y el
  botón puede ir en cualquier lugar del layout del usuario.
* Implementación desacoplada en `lib/src/` y exportada desde el paquete.
* Optimización de recursos: `ValueNotifier` para el reorden en vivo (solo se
  reconstruye el grid durante el arrastre, no el widget completo ni la celda
  final) y `RepaintBoundary` para aislar el pintado del grid.
* Preservación de estado mediante claves y `findChildIndexCallback`.
* Sin dependencias externas.