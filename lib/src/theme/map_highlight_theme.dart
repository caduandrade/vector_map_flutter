import 'package:flutter/material.dart';
import 'package:vector_map/src/theme/map_theme.dart';

/// The theme for highlights.
///
/// This theme is activated by hover or external components like a legend.
class MapHighlightTheme {
  /// Builds a [MapHighlightTheme]
  MapHighlightTheme(
      {this.color,
      this.contourColor,
      this.overlayContour = false,
      this.labelVisibility,
      this.labelStyleBuilder});

  final Color? color;
  final Color? contourColor;
  final bool overlayContour;
  final LabelVisibility? labelVisibility;
  final LabelStyleBuilder? labelStyleBuilder;

  /// Indicates whether the theme has any value set.
  bool hasValue() {
    return color != null || contourColor != null || labelVisibility != null;
  }
}
