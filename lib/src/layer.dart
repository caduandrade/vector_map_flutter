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

  /// Indicates if the hover is paintable, if there is any hover theme and
  /// if it has a set value.
  bool get hoverPaintable {
    return hoverTheme != null && hoverTheme!.hasValue();
  }

  /// Gets the bounds of the layers. Returns [NULL] if the list is empty.
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
