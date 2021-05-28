import 'package:flutter/painting.dart';
import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/theme.dart';

/// Layer for [VectorMap].
class MapLayer {
  MapLayer(
      {required this.dataSource, MapTheme? theme, this.hoverTheme, this.name})
      : this.theme = theme != null ? theme : MapTheme();

  final MapDataSource dataSource;
  final MapTheme theme;
  final MapTheme? hoverTheme;
  final String? name;

  bool get hoverPaintable {
    return hoverTheme != null && hoverTheme!.hasValue();
  }

  static Rect? boundsOf(List<MapLayer> layers) {
    Rect? bounds;
    if (layers.isNotEmpty) {
      bounds = layers.first.dataSource.bounds;
      for (MapLayer layer in layers) {
        bounds = bounds!.expandToInclude(layer.dataSource.bounds);
      }
    }
    return bounds;
  }
}
