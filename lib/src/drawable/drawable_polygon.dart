import 'dart:ui';

import 'package:vector_map/src/drawable/drawable_path.dart';

/// Defines a polygon or multi polygon to be painted on the map.
class DrawablePolygon extends DrawablePath {
  DrawablePolygon(Path path, int pointsCount) : super(path, pointsCount);

  @override
  bool get hasFill => true;
}
