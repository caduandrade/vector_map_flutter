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
}

/// Matrix used to create a buffer image of the map.
class BufferCreationMatrix {
  BufferCreationMatrix._(
      {required this.imageWidth,
      required this.imageHeight,
      required this.scale,
      required this.translateX,
      required this.translateY});

  factory BufferCreationMatrix(
      {required CanvasMatrix canvasMatrix, required Rect geometryBounds}) {
    double scale = canvasMatrix.scale;
    double translateX = -canvasMatrix.scale * geometryBounds.left;
    double translateY = canvasMatrix.scale * geometryBounds.bottom;
    return BufferCreationMatrix._(
        imageWidth: geometryBounds.width * scale,
        imageHeight: geometryBounds.height * scale,
        scale: scale,
        translateX: translateX,
        translateY: translateY);
  }

  final double imageWidth;
  final double imageHeight;
  final double scale;
  final double translateX;
  final double translateY;
}

/// Matrix used to paint the map image buffer.
class BufferPaintMatrix {
  BufferPaintMatrix._(
      {required this.scale,
      required this.translateX,
      required this.translateY});

  factory BufferPaintMatrix(
      {required double widgetWidth,
      required double widgetHeight,
      required int bufferWidth,
      required int bufferHeight}) {
    double scaleX = widgetWidth / bufferWidth;
    double scaleY = widgetHeight / bufferHeight;
    double scale = math.min(scaleX, scaleY);

    double translateX = (widgetWidth / 2.0) - (scale * bufferWidth / 2);
    double translateY = (widgetHeight / 2.0) - (scale * bufferHeight / 2);

    return BufferPaintMatrix._(
        scale: scale, translateX: translateX, translateY: translateY);
  }

  final double scale;
  final double translateX;
  final double translateY;
}

/// Container for all matrices.
class MapMatrices {
  MapMatrices._(
      {required this.canvasMatrix,
      required this.bufferCreationMatrix,
      this.bufferPaintMatrix});

  final CanvasMatrix canvasMatrix;
  final BufferCreationMatrix bufferCreationMatrix;
  final BufferPaintMatrix? bufferPaintMatrix;

  factory MapMatrices(
      {required double widgetWidth,
      required double widgetHeight,
      required Rect geometryBounds,
      required int? bufferWidth,
      required int? bufferHeight}) {
    CanvasMatrix canvasMatrix = CanvasMatrix(
        widgetWidth: widgetWidth,
        widgetHeight: widgetHeight,
        geometryBounds: geometryBounds);

    BufferCreationMatrix bufferCreationMatrix = BufferCreationMatrix(
        canvasMatrix: canvasMatrix, geometryBounds: geometryBounds);

    BufferPaintMatrix? bufferPaintMatrix;
    if (bufferWidth != null && bufferHeight != null) {
      bufferPaintMatrix = BufferPaintMatrix(
          widgetWidth: widgetWidth,
          widgetHeight: widgetHeight,
          bufferWidth: bufferWidth,
          bufferHeight: bufferHeight);
    }

    return MapMatrices._(
        canvasMatrix: canvasMatrix,
        bufferCreationMatrix: bufferCreationMatrix,
        bufferPaintMatrix: bufferPaintMatrix);
  }
}
