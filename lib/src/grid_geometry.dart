part of 'reorderable_grid_view.dart';

/// Geometría calculada de las celdas del grid, reutilizada para el efecto
/// "empujar" (misma fórmula que `SliverGridDelegateWithFixedCrossAxisCount`).
final class _GridGeometry {
  const _GridGeometry({
    required this.columns,
    required this.cellWidth,
    required this.cellHeight,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
  });

  factory _GridGeometry.fromConstraints(
    BoxConstraints constraints, {
    required int columns,
    required double crossAxisSpacing,
    required double mainAxisSpacing,
    required double childAspectRatio,
  }) {
    final double crossAxisExtent = constraints.maxWidth;
    final double cellWidth =
        (crossAxisExtent - crossAxisSpacing * (columns - 1)) / columns;
    final double cellHeight = cellWidth / childAspectRatio;
    return _GridGeometry(
      columns: columns,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  /// Número de columnas.
  final int columns;

  /// Ancho de cada celda.
  final double cellWidth;

  /// Alto de cada celda.
  final double cellHeight;

  /// Espaciado horizontal entre columnas.
  final double crossAxisSpacing;

  /// Espaciado vertical entre filas.
  final double mainAxisSpacing;

  /// Distancia horizontal entre el inicio de dos celdas adyacentes.
  double get pitchX => cellWidth + crossAxisSpacing;

  /// Distancia vertical entre el inicio de dos celdas adyacentes.
  double get pitchY => cellHeight + mainAxisSpacing;
}
