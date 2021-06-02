import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Matrix to convert world coordinates to screen coordinates.
class CanvasMatrix {
  CanvasMatrix._(
      {required this.scale,
      required this.translateX,
      required this.translateY,
      required this.widgetSize,
      required this.geometryToScreen,
      required this.screenToGeometry});

  factory CanvasMatrix(
      {required double widgetWidth,
      required double widgetHeight,
      required Rect geometryBounds}) {
    double scaleX = widgetWidth / geometryBounds.width;
    double scaleY = widgetHeight / geometryBounds.height;
    double scale = math.min(scaleX, scaleY);

    double translateX =
        (widgetWidth / 2.0) - (scale * geometryBounds.center.dx);
    double translateY =
        (widgetHeight / 2.0) + (scale * geometryBounds.center.dy);

    Matrix4 geometryToScreen = Matrix4(
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

    geometryToScreen.translate(translateX, translateY, 0);
    geometryToScreen.scale(scale, -scale, 1);

    Matrix4 screenToGeometry = Matrix4.inverted(geometryToScreen);

    return CanvasMatrix._(
        scale: scale,
        translateX: translateX,
        translateY: translateY,
        widgetSize: Size(widgetWidth, widgetHeight),
        geometryToScreen: geometryToScreen,
        screenToGeometry: screenToGeometry);
  }

  final double scale;
  final double translateX;
  final double translateY;
  final Size widgetSize;
  final Matrix4 geometryToScreen;
  final Matrix4 screenToGeometry;

  /// Applies a matrix on the canvas.
  applyOn(Canvas canvas) {
    canvas.translate(translateX, translateY);
    canvas.scale(scale, -scale);
  }
}
