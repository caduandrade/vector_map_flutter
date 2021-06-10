import 'dart:ui';

/// Defines how a [MapFeature] should be painted on the map.
abstract class PaintableFeature {
  /// Gets the geometry bounds
  Rect getBounds();

  /// Draws this paintable on the canvas.
  drawOn(Canvas canvas, Paint paint, double scale);

  /// Gets the count of points for this paintable.
  int get pointsCount;

  /// Checks whether a point is contained in this paintable.
  bool contains(Offset offset);

  /// Indicates whether it is visible.
  bool get visible;

  /// Indicates whether to draw the fill
  bool get hasFill;
}
