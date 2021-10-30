import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/drawable/drawable.dart';

class DrawableFeature {
  DrawableFeature(this.feature);

  final MapFeature feature;
  Drawable? drawable;
}
