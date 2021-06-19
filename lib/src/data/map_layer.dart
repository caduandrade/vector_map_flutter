import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/theme/map_highlight_theme.dart';
import 'package:vector_map/src/theme/map_theme.dart';

/// Layer for [VectorMap].
class MapLayer {
  MapLayer(
      {int? id,
      required this.dataSource,
      MapTheme? theme,
      this.highlightTheme,
      this.name})
      : this.id = id != null ? id : _randomId(),
        this.theme = theme != null ? theme : MapTheme();

  final int id;
  final MapDataSource dataSource;
  final MapTheme theme;
  final MapHighlightTheme? highlightTheme;
  final String? name;

  /// Indicates if the hover is drawable, if there is any highlight theme and
  /// if it has a set value.
  bool get hoverDrawable {
    return highlightTheme != null && highlightTheme!.hasValue();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLayer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

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

  /// Gets a random layer id.
  static int _randomId() {
    Random random = Random();
    return random.nextInt(9999999);
  }
}
