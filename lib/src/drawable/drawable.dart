import 'dart:ui';

/// Defines how a [MapFeature] should be painted on the map.
abstract class Drawable {
  /// Gets the geometry bounds
  Rect getBounds();

  /// Draws this drawable on the canvas.
  void drawOn(Canvas canvas, Paint paint, double scale);

  /// Gets the count of points for this drawable.
  int get pointsCount;

  /// Checks whether a point is contained in this drawable.
  bool contains(Offset offset);

  /// Indicates whether it is visible.
  bool get visible;

  /// Indicates whether to draw the fill
  bool get hasFill;
}
