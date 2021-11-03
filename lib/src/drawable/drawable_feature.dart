import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/drawable/drawable.dart';

class DrawableFeature {
  DrawableFeature(this.feature);

  final MapFeature feature;
  Drawable? drawable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawableFeature &&
          runtimeType == other.runtimeType &&
          feature == other.feature;

  @override
  int get hashCode => feature.hashCode;
}
