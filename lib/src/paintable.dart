import 'dart:ui';

/// Defines how a [MapFeature] should be painted on the map.
abstract class PaintableFeature {
  /// Gets the geometry bounds
  Rect getBounds();

  /// Draws this paintable on the canvas.
  drawOn(Canvas canvas, Paint paint);

  /// Gets the count of points for this paintable.
  int get pointsCount;

  /// Checks whether a point is contained in this paintable.
  bool contains(Offset offset);
}

/// Defines a path to be painted on the map.
class PaintablePath extends PaintableFeature {
  PaintablePath(Path path, int pointsCount)
      : this._path = path,
        this._pointsCount = pointsCount;

  final Path _path;
  final int _pointsCount;

  @override
  drawOn(Canvas canvas, Paint paint) {
    canvas.drawPath(_path, paint);
  }

  @override
  Rect getBounds() {
    return _path.getBounds();
  }

  @override
  bool contains(Offset offset) {
    return _path.contains(offset);
  }

  @override
  int get pointsCount => _pointsCount;
}

/// [Marker] builder.
typedef MarkerBuilder = Marker Function(Offset offset, double scale);

/// Defines a marker to be painted on the map.
abstract class Marker extends PaintableFeature {
  Marker({required this.offset});

  final Offset offset;

  @override
  drawOn(Canvas canvas, Paint paint) {
    drawMarkerOn(canvas, paint, offset);
  }

  @override
  int get pointsCount => 1;

  drawMarkerOn(Canvas canvas, Paint paint, Offset offset);
}

/// Defines a circle marker to be painted on the map.
class CircleMaker extends Marker {
  CircleMaker({required Offset offset, required double radius})
      : this._bounds = Rect.fromLTWH(
            offset.dx - radius, offset.dy - radius, radius * 2, radius * 2),
        this._radius = radius,
        super(offset: offset);

  final Rect _bounds;
  final double _radius;

  @override
  bool contains(Offset offset) {
    return _bounds.contains(offset);
  }

  @override
  drawMarkerOn(Canvas canvas, Paint paint, Offset offset) {
    canvas.drawCircle(offset, _radius, paint);
  }

  @override
  Rect getBounds() {
    return _bounds;
  }
}
