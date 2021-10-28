import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Matrix to convert world coordinates to screen coordinates.
class CanvasMatrix {
  CanvasMatrix._(
      {required this.scale,
      required this.translateX,
      required this.translateY,
      required this.widgetSize,
      required this.worldToScreen,
      required this.screenToWorld});

  /// Builds a [CanvasMatrix]
  ///
  /// The [worldBounds] represents the bounds from the data source.
  factory CanvasMatrix(
      {required double widgetWidth,
      required double widgetHeight,
      required Rect worldBounds}) {
    double scaleX = widgetWidth / worldBounds.width;
    double scaleY = widgetHeight / worldBounds.height;
    double scale = math.min(scaleX, scaleY);

    double translateX = (widgetWidth / 2.0) - (scale * worldBounds.center.dx);
    double translateY = (widgetHeight / 2.0) + (scale * worldBounds.center.dy);

    Matrix4 worldToScreen = Matrix4(
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
    );

    worldToScreen.translate(translateX, translateY, 0);
    worldToScreen.scale(scale, -scale, 1);

    Matrix4 screenToWorld = Matrix4.inverted(worldToScreen);

    return CanvasMatrix._(
        scale: scale,
        translateX: translateX,
        translateY: translateY,
        widgetSize: Size(widgetWidth, widgetHeight),
        worldToScreen: worldToScreen,
        screenToWorld: screenToWorld);
  }

  final double scale;
  final double translateX;
  final double translateY;
  final Size widgetSize;

  /// Matrix to be used to convert world coordinates to screen coordinates.
  final Matrix4 worldToScreen;

  /// Matrix to be used to convert screen coordinates to world coordinates.
  final Matrix4 screenToWorld;

  /// Applies a matrix on the canvas.
  void applyOn(Canvas canvas) {
    canvas.translate(translateX, translateY);
    canvas.scale(scale, -scale);
  }
}
