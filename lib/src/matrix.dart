import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Matrix to convert world coordinates to screen coordinates.
class CanvasMatrix {
  /// Builds a [CanvasMatrix]
  ///
  /// The [worldBounds] represents the bounds from the data source.
  CanvasMatrix({required Rect? worldBounds}) : this._worldBounds = worldBounds;

  void fit() {
    _scale = 1;
    _translateX = 0;
    _translateY = 0;

    if (worldBounds != null && canvasSize.isEmpty == false) {
      double scaleX = canvasSize.width / worldBounds!.width;
      double scaleY = canvasSize.height / worldBounds!.height;
      _scale = math.min(scaleX, scaleY);

      _translateX = (canvasSize.width / 2.0) - (scale * worldBounds!.center.dx);
      _translateY =
          (canvasSize.height / 2.0) + (scale * worldBounds!.center.dy);
    }

    _worldToScreen = CanvasMatrix._buildMatrix4();
    _worldToScreen.translate(_translateX, _translateY, 0);
    _worldToScreen.scale(_scale, -_scale, 1);

    _screenToWorld = Matrix4.inverted(_worldToScreen);
  }

  Rect? _worldBounds;
  Rect? get worldBounds => _worldBounds;

  double _scale = 1;
  double get scale => _scale;

  double _translateX = 0;

  double _translateY = 0;

  Size canvasSize = Size(0, 0);

  /// Matrix to be used to convert world coordinates to screen coordinates.
  Matrix4 _worldToScreen = CanvasMatrix._buildMatrix4();
  Matrix4 get worldToScreen => _worldToScreen;

  /// Matrix to be used to convert screen coordinates to world coordinates.
  Matrix4 _screenToWorld = CanvasMatrix._buildMatrix4();
  Matrix4 get screenToWorld => _screenToWorld;

  /// Applies a matrix on the canvas.
  void applyOn(Canvas canvas) {
    canvas.translate(_translateX, _translateY);
    canvas.scale(_scale, -_scale);
  }

  static Matrix4 _buildMatrix4() {
    return Matrix4(
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
  }
}
