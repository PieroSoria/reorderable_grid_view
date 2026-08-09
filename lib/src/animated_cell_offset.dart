part of 'reorderable_grid_view.dart';

/// Envuelve una celda para que se deslice con una animación suave desde su
/// posición anterior hasta su posición actual. Es la base del efecto
/// "empujar": cuando una celda cambia de sitio al reordenarse la lista en
/// vivo, se anima desde su ubicación anterior.
final class _AnimatedCellOffset extends StatefulWidget {
  const _AnimatedCellOffset({
    required this.start,
    required this.duration,
    required this.child,
  });

  /// Posición de la que parte la celda (relativa a su posición final).
  final Offset start;

  /// Duración de la animación de deslizamiento.
  final Duration duration;

  /// Contenido de la celda.
  final Widget child;

  @override
  _AnimatedCellOffsetState createState() => _AnimatedCellOffsetState();
}

final class _AnimatedCellOffsetState extends State<_AnimatedCellOffset>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..value = 1.0;

  late Animation<Offset> _animation = _buildAnimation();

  Animation<Offset> _buildAnimation() {
    return Tween<Offset>(
      begin: widget.start,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(_AnimatedCellOffset oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start) {
      _animation = _buildAnimation();
      _controller
        ..value = 0.0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _animation, child: widget.child);
  }
}
