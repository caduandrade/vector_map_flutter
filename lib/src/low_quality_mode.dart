import 'package:flutter/material.dart';

/// The low-quality mode can be used during resizing, panning,
/// and zooming to optimize the drawing.
///
/// Allows you to simplify drawing during these events avoiding freezes.
/// The default [quality] value is 0.3.
class LowQualityMode {
  LowQualityMode(
      {this.quality = 0.3,
      this.strokeColor = Colors.black,
      this.fillEnabled = false}) {
    if (this.quality <= 0 || this.quality > 1) {
      throw ArgumentError(
          'Quality value must be greater than 0 and less than or equal to 1');
    }
  }

  /// Defines the quality of the geometries that will be drawn during events.
  /// Value 1 represents 100% quality.
  final double quality;

  /// Color to paint the edge of geometries.
  /// If null, the color defined by the theme will be used.
  final Color? strokeColor;

  final bool fillEnabled;
}
