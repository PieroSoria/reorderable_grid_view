import 'package:flutter/material.dart';

// Desacoplamiento en archivos privados de la misma librería:
part 'animated_cell_offset.dart';
part 'grid_geometry.dart';

/// Builder usado para construir la representación visual de cada elemento.
///
/// [context] es el [BuildContext] del grid, [item] es el elemento actual y
/// [index] es su posición dentro de `items`.
typedef ReorderableGridItemBuilder<T> =
    Widget Function(BuildContext context, T item, int index);

/// Builder opcional para personalizar el *feedback* que se muestra bajo el
/// puntero mientras se arrastra un elemento.
///
/// Recibe como argumento el widget del elemento (tal y como lo devolvió
/// [ReorderableGrid.itemBuilder]). Si no se proporciona, se usa el
/// *feedback* por defecto (escala 1.05, opacidad 0.8 y sombra ligera).
typedef ReorderableGridFeedbackBuilder = Widget Function(Widget item);

/// Builder opcional para personalizar el widget que se muestra en el hueco
/// original mientras un elemento está siendo arrastrado.
///
/// Si no se proporciona, se muestra el widget del elemento con opacidad 0.2.
typedef ReorderableGridPlaceholderBuilder = Widget Function(Widget item);

/// Un [GridView] de elementos reordenables mediante *drag and drop* nativo.
///
/// Implementa el reordenamiento usando únicamente [LongPressDraggable] y
/// [DragTarget] de Flutter, sin dependencias externas.
///
/// ## Semántica del reordenamiento
///
/// A diferencia de [ReorderableListView], este widget NO aplica el
/// desplazamiento `newIndex -= 1` cuando `oldIndex < newIndex`. El significado
/// de la llamada a [onReorder] es **"sitúa el elemento en [oldIndex] en la
/// posición [newIndex]"** (índice final directo). Un handler típico sería:
///
/// ```dart
/// void _onReorder(int oldIndex, int newIndex) {
///   if (oldIndex == newIndex) return;
///   setState(() {
///     final T item = _items.removeAt(oldIndex);
///     _items.insert(newIndex, item);
///   });
/// }
/// ```
///
/// `T` debe tener una identidad estable. Si no se proporciona [itemKey], se
/// usará por defecto `ValueKey<T>(item)`, por lo que los elementos deben
/// sobrescribir `==` y `hashCode` (o ser instancias mantenidas estables)
/// para que Flutter conserve el estado de los widgets durante el reordenamiento.
///
/// ## Efecto "empujar" durante el arrastre
///
/// Con [liveReorder] habilitado (por defecto), mientras se arrastra un elemento
/// los vecinos se apartan en vivo: el grid se reorganiza paso a paso sobre la
/// celda sobrevolada y las celdas se deslizan con una animación suave, creando
/// el hueco por el que se desplaza el elemento. Al soltarlo, [onReorder] se
/// invoca con la posición final resultante.
///
/// ## Celda final fija (opcional)
///
/// El grid puede terminar con una celda estática y **no arrastrable** que
/// siempre ocupa la última posición. Es totalmente opcional:
///
/// * Si [onAddItemBuilder] es `null`, no se añade ninguna celda final y el
///   botón "Agregar" puede ir en cualquier otro sitio de tu propio layout.
/// * Si se pasa [onAddItemBuilder], se usa el widget que devuelva (puede
///   devolver a su vez `null` para no mostrar ninguna celda final).
///
/// En cualquier caso, soltar un elemento sobre esa celda final lo mueve a la
/// última posición de la lista.
///
/// ## Dentro de un `CustomScrollView`
///
/// Para combinarlo con otros *slivers* usa la variante [SliverReorderableGrid],
/// que expone la misma lógica (reordenamiento, empuje y celda final) pero
/// renderiza mediante un `SliverGrid` perezoso.
class ReorderableGrid<T> extends _ReorderableGridBase<T> {
  /// Crea un [ReorderableGrid].
  const ReorderableGrid({
    super.key,
    required super.items,
    required super.itemBuilder,
    required super.onReorder,
    super.onAddItemBuilder,
    super.itemKey,
    super.feedbackBuilder,
    super.childWhenDraggingBuilder,
    super.liveReorder,
    super.crossAxisCount,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
    super.childAspectRatio,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  /// Si es `true`, el grid se ajusta a la altura de su contenido para poder
  /// ser anidado en widgets como un [SingleChildScrollView].
  final bool shrinkWrap;

  /// Física de scroll del grid. Por defecto no es desplazable.
  final ScrollPhysics physics;
}

/// La variante *sliver* de [ReorderableGrid], para usarse dentro de un
/// [CustomScrollView] (o cualquier lugar donde se necesite un [SliverGrid]).
///
/// Expone exactamente los mismos parámetros que [ReorderableGrid] (salvo
/// [ReorderableGrid.shrinkWrap] y [ReorderableGrid.physics], que no aplican a
/// un sliver) y comparte la misma lógica: reordenamiento por presión larga,
/// efecto "empujar" con [SliverReorderableGrid.liveReorder] y la celda final
/// opcional [SliverReorderableGrid.onAddItemBuilder].
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverPadding(
///       padding: const EdgeInsets.all(16),
///       sliver: SliverReorderableGrid<String>(
///         items: _items,
///         onReorder: _onReorder,
///         itemBuilder: (context, item, index) => _ItemCard(item),
///         crossAxisCount: 3,
///         childAspectRatio: 3 / 4,
///       ),
///     ),
///   ],
/// )
/// ```
class SliverReorderableGrid<T> extends _ReorderableGridBase<T> {
  /// Crea un [SliverReorderableGrid].
  const SliverReorderableGrid({
    super.key,
    required super.items,
    required super.itemBuilder,
    required super.onReorder,
    super.onAddItemBuilder,
    super.itemKey,
    super.feedbackBuilder,
    super.childWhenDraggingBuilder,
    super.liveReorder,
    super.crossAxisCount,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
    super.childAspectRatio,
  });
}

/// Configuración y parámetros comunes compartidos entre [ReorderableGrid] y
/// [SliverReorderableGrid].
///
/// Es una clase interna: los dos widgets públicos difieren solo en que el
/// primero produce un `GridView` (widget de caja) y el segundo un `SliverGrid`
/// (sliver dentro de un `CustomScrollView`).
abstract class _ReorderableGridBase<T> extends StatefulWidget {
  const _ReorderableGridBase({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onReorder,
    this.onAddItemBuilder,
    this.itemKey,
    this.feedbackBuilder,
    this.childWhenDraggingBuilder,
    this.liveReorder = true,
    this.crossAxisCount = 4,
    this.mainAxisSpacing = 6.0,
    this.crossAxisSpacing = 6.0,
    this.childAspectRatio = 3 / 4,
  });

  /// La lista de elementos que se renderizan y reordenan.
  ///
  /// El widget es "controlado": la lista la posee el padre y este widget solo
  /// la lee. Tras una operación de arrastre se invoca [onReorder] y el padre
  /// debe actualizar la lista y reconstruir este widget.
  final List<T> items;

  /// Función que construye el [Widget] de cada elemento.
  final ReorderableGridItemBuilder<T> itemBuilder;

  /// Callback que se invoca cuando un elemento cambia de posición.
  ///
  /// [oldIndex] es la posición original del elemento y [newIndex] la posición
  /// final a la que debe moverse (ver la nota de la clase). Solo se invoca si
  /// los índices son diferentes.
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Builder opcional del widget fijo que aparece al final del grid (por
  /// ejemplo, un botón "+ Agregar").
  ///
  /// Si devuelve `null` — o si este parámetro es `null` — no se añade ninguna
  /// celda final y el botón "Agregar" puede ir en cualquier otro lugar del
  /// layout del usuario.
  ///
  /// La celda construida nunca es arrastrable. Además actúa como un
  /// [DragTarget]: si se suelta un elemento sobre ella, se llama a
  /// `onReorder(oldIndex, items.length - 1)` (el elemento va a la última
  /// posición).
  final Widget? Function(BuildContext context)? onAddItemBuilder;

  /// Callback que devuelve una [Key] única y estable para cada elemento.
  ///
  /// Si es `null`, se usa `ValueKey<T>(item)` como clave por defecto. Las
  /// claves son necesarias para que Flutter conserve el estado de los widgets
  /// (por ejemplo, un `TextEditingController`) cuando estos cambian de celda
  /// tras un reordenamiento.
  final Key Function(T item)? itemKey;

  /// Personaliza el widget que se muestra debajo del dedo durante el arrastre.
  final ReorderableGridFeedbackBuilder? feedbackBuilder;

  /// Personaliza el widget que ocupa el hueco original del elemento mientras
  /// este se arrastra.
  final ReorderableGridPlaceholderBuilder? childWhenDraggingBuilder;

  /// Si es `true` (por defecto), al arrastrar un elemento se muestra el efecto
  /// "empujar": el grid se reorganiza en vivo sobre la celda sobrevolada y las
  /// celdas se deslizan para dejar pasar al elemento arrastrado.
  ///
  /// Con `false`, el reordenamiento se aplica solo al soltar (los vecinos no
  /// se mueven durante el arrastre).
  final bool liveReorder;

  /// Número de columnas del grid.
  final int crossAxisCount;

  /// Espaciado vertical entre filas.
  final double mainAxisSpacing;

  /// Espaciado horizontal entre columnas.
  final double crossAxisSpacing;

  /// Relación ancho/alto de cada celda.
  final double childAspectRatio;

  @override
  State<_ReorderableGridBase<T>> createState() => _ReorderableGridState<T>();
}

class _ReorderableGridState<T> extends State<_ReorderableGridBase<T>> {
  /// Clave estable y única para la celda final.
  static const Key _footerKey = ValueKey<String>('__reorderable_grid_footer__');

  /// Color de la sombra ligera del *feedback* por defecto.
  static const Color _feedbackShadowColor = Color(0x26000000);

  /// Color del borde que resalta la celda de destino durante el arrastre.
  static const Color _hoverHighlightColor = Color(0xFF2196F3);

  /// Ancho del borde de resaltado del destino.
  static const double _hoverHighlightWidth = 2.5;

  /// Duración de la animación de deslizamiento del efecto "empujar".
  static const Duration _pushDuration = Duration(milliseconds: 220);

  /// Celda final resuelta en el último [build] (cacheada por pasada para no
  /// invocar [onAddItemBuilder] varias veces por frame).
  Widget? _resolvedAddItemCell;

  /// Lista que se muestra durante un arrastre con [liveReorder].
  ///
  /// `null` fuera del arrastre; durante el arrastre contiene una copia de
  /// [ReorderableGrid.items] que se reordena en vivo mientras el elemento
  /// sobrevuela celdas.
  ///
  /// Es un [ValueNotifier] para que cada cambio de orden durante el arrastre
  /// reconstruya **solo el grid** (vía `ValueListenableBuilder`) y no el
  /// [State] completo: evita re-resolver la celda final ([onAddItemBuilder])
  /// y re-crear el `LayoutBuilder` en cada paso del arrastre.
  final ValueNotifier<List<T>?> _preview = ValueNotifier<List<T>?>(null);

  /// Índice original (en la lista del padre) del elemento que se arrastra.
  int? _originalIndex;

  /// Posición actual dentro de [_preview] del elemento que se arrastra.
  int? _previewMovedIndex;

  /// Último índice en el que se dibujó cada clave, para calcular el
  /// desplazamiento inicial de la animación de deslizamiento.
  final Map<Key, int> _lastIndexByKey = <Key, int>{};

  /// La lista que se renderiza: durante un arrastre la previsualización, en
  /// reposo la lista controlada del padre.
  List<T> get _displayed => _preview.value ?? widget.items;

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  /// Resuelve la clave de un elemento: usa [ReorderableGrid.itemKey] si está
  /// definido o cae en `ValueKey<T>(item)` en caso contrario.
  Key _keyOf(T item) => widget.itemKey?.call(item) ?? ValueKey<T>(item);

  /// `true` cuando el grid debe mostrar una celda final fija.
  bool get _hasFooterCell => _resolvedAddItemCell != null;

  /// Permite al delegado de children localizar, mediante su clave, el índice
  /// de un elemento (o de la celda final) para conservar el estado de los
  /// widgets cuando la cuadrícula se reordena.
  int? _findChildIndexByKey(Key key) {
    final List<T> displayed = _displayed;
    if (key == _footerKey && _hasFooterCell) {
      return displayed.length;
    }
    for (var i = 0; i < displayed.length; i++) {
      if (_keyOf(displayed[i]) == key) return i;
    }
    return null;
  }

  /// Indica si un elemento que se arrastra puede soltarse sobre la celda final.
  ///
  /// Solo se permite cuando existe al menos un elemento y el arrastrado no es
  /// ya el último (cayendo entonces en la última posición).
  bool _canDropOnFooter(int oldIndex) {
    return oldIndex >= 0 &&
        widget.items.isNotEmpty &&
        oldIndex != widget.items.length - 1;
  }

  /// Resuelve la celda final: usa [onAddItemBuilder] si está definido, o `null`
  /// en caso contrario (sin celda final).
  Widget? _resolveAddItemCell(BuildContext context) {
    return widget.onAddItemBuilder?.call(context);
  }

  /// Inicia una operación de arrastre: congela una previsualización de la
  /// lista que se podrá reordenar en vivo sin tocar la lista del padre.
  void _beginDrag(int index) {
    _originalIndex = index;
    _previewMovedIndex = index;
    // Sin animaciones al iniciar el arrastre.
    _lastIndexByKey.clear();
    _preview.value = List<T>.of(widget.items);
  }

  /// Reordena la previsualización moviendo al elemento arrastrado (que está en
  /// [_previewMovedIndex]) a la posición [targetIndex].
  void _previewMoveTo(int targetIndex) {
    final List<T>? preview = _preview.value;
    final int? moved = _previewMovedIndex;
    if (preview == null ||
        moved == null ||
        targetIndex == moved ||
        targetIndex < 0 ||
        targetIndex >= preview.length) {
      return;
    }
    final List<T> reordered = List<T>.of(preview);
    final T dragged = reordered.removeAt(moved);
    reordered.insert(targetIndex, dragged);
    _previewMovedIndex = targetIndex;
    _preview.value = reordered;
  }

  /// Confirma el arrastre: restaura la vista controlada del padre e invoca
  /// [onReorder] con la posición final del elemento.
  ///
  /// Si [finalIndex] es `null` se usa la posición actual de la previsualización
  /// ([_previewMovedIndex]); en caso contrario `finalIndex` (p. ej. la última
  /// posición al soltar sobre la celda final).
  void _commitDrag({int? finalIndex}) {
    final int? original = _originalIndex;
    final int? moved = finalIndex ?? _previewMovedIndex;

    _preview.value = null;
    _previewMovedIndex = null;
    _originalIndex = null;

    if (original != null && moved != null && original != moved) {
      widget.onReorder(original, moved);
    }
  }

  /// Cancela el arrastre: descarta la previsualización y devuelve la lista a
  /// su orden original (las celdas se deslizan de vuelta).
  void _cancelDrag() {
    _preview.value = null;
    _previewMovedIndex = null;
    _originalIndex = null;
  }

  /// Calcula la distancia (en fracciones del tamaño de la celda) que separa la
  /// posición anterior [previousIndex] de la posición actual [index]. Es el
  /// punto de partida de la animación de deslizamiento de la celda.
  Offset _dragOffset(int previousIndex, int index, _GridGeometry geometry) {
    if (previousIndex == index) return Offset.zero;
    final int prevCol = previousIndex % geometry.columns;
    final int prevRow = previousIndex ~/ geometry.columns;
    final int curCol = index % geometry.columns;
    final int curRow = index ~/ geometry.columns;

    return Offset(
      (prevCol - curCol) * (geometry.pitchX / geometry.cellWidth),
      (prevRow - curRow) * (geometry.pitchY / geometry.cellHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    _resolvedAddItemCell = _resolveAddItemCell(context);

    // El grid escucha los cambios del orden en vivo (arrastre) para
    // reconstruirse solo él, sin reconstruir el resto del widget.
    return ValueListenableBuilder<List<T>?>(
      valueListenable: _preview,
      builder: (context, preview, _) {
        final bool hasFooter = _hasFooterCell;
        final int itemCount =
            (preview ?? widget.items).length + (hasFooter ? 1 : 0);

        // Variante "caja": un GridView (puede anidarse y desplazarse solo).
        if (widget is ReorderableGrid<T>) {
          final ReorderableGrid<T> box = widget as ReorderableGrid<T>;
          return RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final _GridGeometry geometry = _GridGeometry.fromConstraints(
                  constraints,
                  columns: widget.crossAxisCount,
                  crossAxisSpacing: widget.crossAxisSpacing,
                  mainAxisSpacing: widget.mainAxisSpacing,
                  childAspectRatio: widget.childAspectRatio,
                );

                return GridView.builder(
                  shrinkWrap: box.shrinkWrap,
                  physics: box.physics,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.crossAxisCount,
                    mainAxisSpacing: widget.mainAxisSpacing,
                    crossAxisSpacing: widget.crossAxisSpacing,
                    childAspectRatio: widget.childAspectRatio,
                  ),
                  itemCount: itemCount,
                  // Clave -> índice, para migrar correctamente los elementos
                  // existentes (conservando su Estado) a sus nuevas celdas.
                  findChildIndexCallback: _findChildIndexByKey,
                  itemBuilder: (context, index) {
                    final bool isFooter = hasFooter && index == itemCount - 1;
                    return isFooter
                        ? _buildFooter(context)
                        : _buildItem(context, index, geometry);
                  },
                );
              },
            ),
          );
        }

        // Variante sliver: un SliverGrid para usar dentro de un
        // CustomScrollView.
        return SliverLayoutBuilder(
          builder: (context, constraints) {
            final _GridGeometry geometry = _GridGeometry.fromConstraints(
              // El ancho disponible es el eje transversal del sliver.
              BoxConstraints(maxWidth: constraints.crossAxisExtent),
              columns: widget.crossAxisCount,
              crossAxisSpacing: widget.crossAxisSpacing,
              mainAxisSpacing: widget.mainAxisSpacing,
              childAspectRatio: widget.childAspectRatio,
            );

            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
                mainAxisSpacing: widget.mainAxisSpacing,
                crossAxisSpacing: widget.crossAxisSpacing,
                childAspectRatio: widget.childAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final bool isFooter = hasFooter && index == itemCount - 1;
                  return isFooter
                      ? _buildFooter(context)
                      : _buildItem(context, index, geometry);
                },
                childCount: itemCount,
                findChildIndexCallback: _findChildIndexByKey,
              ),
            );
          },
        );
      },
    );
  }

  /// Construye una celda deslizable + `DragTarget` para el elemento en [index].
  Widget _buildItem(BuildContext context, int index, _GridGeometry geometry) {
    final T item = _displayed[index];
    final Key key = _keyOf(item);

    // Punto de partida del deslizamiento: desde dónde venía la celda.
    final int? previousIndex = _lastIndexByKey[key];
    _lastIndexByKey[key] = index;
    final Offset start = previousIndex == null
        ? Offset.zero
        : _dragOffset(previousIndex, index, geometry);

    return KeyedSubtree(
      // Clave del elemento: fundamental para conservar el estado del widget
      // (y la animación de deslizamiento) cuando el grid se reordena.
      key: key,
      child: _AnimatedCellOffset(
        start: start,
        duration: _pushDuration,
        child: DragTarget<int>(
          // Se acepta un arrastre salvo cuando se suelta sobre la celda que
          // ya ocupa el elemento (compara el índice original transportado con
          // la celda sobrevolada).
          onWillAcceptWithDetails: (details) {
            if (details.data == index) {
              // Se sobrevuela la celda de origen del elemento arrastrado:
              // revierte cualquier empuje previo para que los vecinos se
              // deslicen de vuelta a su sitio (la preview vuelve al orden
              // original). Se rechaza el destino: soltar aquí no reordena.
              if (widget.liveReorder) {
                _previewMoveTo(details.data);
              }
              return false;
            }
            // Efecto "empujar": mueve en vivo al elemento arrastrado hacia la
            // celda sobrevolada.
            if (widget.liveReorder) {
              _previewMoveTo(index);
            }
            return true;
          },
          onAcceptWithDetails: (details) {
            if (widget.liveReorder) {
              // El índice final es donde quedó el hueco en la previsualización.
              _commitDrag();
            } else if (details.data != index) {
              // Se llama a onReorder únicamente si los índices son distintos.
              widget.onReorder(details.data, index);
            }
          },
          builder: (context, candidateData, rejectedData) {
            // Hay un arrastre encima que sí se aceptaría en esta celda.
            final bool isHovering = candidateData.isNotEmpty;

            return LayoutBuilder(
              builder: (context, constraints) {
                final Widget itemWidget = widget.itemBuilder(
                  context,
                  item,
                  index,
                );

                return LongPressDraggable<int>(
                  // El dato que transporta el arrastre es el índice del
                  // elemento en el momento en que empezó (queda fijo durante
                  // todo el arrastre, aunque la vista se reordene en vivo).
                  data: index,
                  // Asegura que toda la celda reciba el gesto de presión larga.
                  hitTestBehavior: HitTestBehavior.opaque,
                  // El feedback viaja con las dimensiones exactas de la celda,
                  // evitando que los elementos se reescalen al soltarse.
                  feedback: _buildFeedback(itemWidget, constraints.biggest),
                  childWhenDragging: _buildChildWhenDragging(itemWidget),
                  onDragStarted: () => _beginDrag(index),
                  onDraggableCanceled: (velocity, offset) => _cancelDrag(),
                  child: _applyHoverHighlight(itemWidget, isHovering),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Construye la celda final del grid: el widget devuelto por
  /// [ReorderableGrid.onAddItemBuilder] o el botón "Agregar" predefinido.
  ///
  /// Esta celda nunca es un `Draggable` (no se puede mover). Se envuelve en un
  /// [DragTarget] para que, al soltar un elemento sobre ella, dicho elemento
  /// se mueva a la última posición de la lista.
  Widget _buildFooter(BuildContext context) {
    final Widget child = _resolvedAddItemCell!;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => _canDropOnFooter(details.data),
      onAcceptWithDetails: (details) {
        final int oldIndex = details.data;
        if (!_canDropOnFooter(oldIndex)) return;
        if (widget.liveReorder) {
          _commitDrag(finalIndex: widget.items.length - 1);
        } else {
          widget.onReorder(oldIndex, widget.items.length - 1);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;

        return KeyedSubtree(
          key: _footerKey,
          child: _applyHoverHighlight(child, isHovering),
        );
      },
    );
  }

  /// Construye el *feedback* por defecto (o el personalizado) con el tamaño
  /// exacto de la celda, para que no cambie de tamaño durante el arrastre.
  Widget _buildFeedback(Widget item, Size size) {
    final Widget feedback =
        widget.feedbackBuilder?.call(item) ??
        Transform.scale(
          scale: 1.05,
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              boxShadow: [
                BoxShadow(
                  color: _feedbackShadowColor,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Opacity(opacity: 0.8, child: item),
          ),
        );

    return SizedBox.fromSize(
      size: size,
      // Un Material transparente garantiza que los widgets con efectos tinta
      // (p. ej. InkWell) dentro del elemento no fallen durante el arrastre,
      // ya que el feedback se dibuja en el overlay de la aplicación.
      child: Material(type: MaterialType.transparency, child: feedback),
    );
  }

  /// Construye el placeholder que ocupa el hueco original mientras el
  /// elemento se arrastra. Por defecto, el mismo widget con opacidad 0.2.
  Widget _buildChildWhenDragging(Widget item) {
    return widget.childWhenDraggingBuilder?.call(item) ??
        Opacity(opacity: 0.2, child: item);
  }

  /// Resalta visualmente la celda que aceptará el elemento en caso de soltarse,
  /// mostrando un borde fino alrededor de la misma.
  Widget _applyHoverHighlight(Widget child, bool isHovering) {
    if (!isHovering) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hoverHighlightColor,
                  width: _hoverHighlightWidth,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
