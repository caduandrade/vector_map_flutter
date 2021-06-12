import 'package:flutter/material.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';

/// The theme for highlights.
///
/// This theme is activated by external components like a legend.
class MapHighlightTheme {
  /// Builds a [MapHighlightTheme]
  MapHighlightTheme({this.color, this.contourColor});

  final Color? color;
  final Color? contourColor;

  /// Indicates whether the theme has any value set.
  bool hasValue() {
    return color != null || contourColor != null;
  }

  /// Gets the feature color.
  Color? getColor(MapDataSource dataSource, MapFeature feature) {
    return color;
  }
}
