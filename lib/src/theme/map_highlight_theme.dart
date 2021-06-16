import 'package:flutter/material.dart';

/// The theme for highlights.
///
/// This theme is activated by external components like a legend.
class MapHighlightTheme {
  /// Builds a [MapHighlightTheme]
  MapHighlightTheme({this.color, this.contourColor});

  final Color? color;
  final Color? contourColor;
}
