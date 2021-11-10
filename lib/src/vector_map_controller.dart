import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/debugger.dart';
import 'package:vector_map/src/draw_utils.dart';
import 'package:vector_map/src/drawable/drawable_builder.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/drawable/drawable_layer_chunk.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme/map_theme.dart';

class VectorMapController extends ChangeNotifier {
  final List<DrawableLayer> _drawableLayers = [];

  int get drawableLayersLength => _drawableLayers.length;

  DrawableLayer getDrawableLayer(int index) {
    return _drawableLayers[index];
  }

  Size? canvasSize;
  bool _firstUpdate = true;
  bool get firstUpdate => _firstUpdate;

  /// Represents the bounds of all layers.
  Rect? _worldBounds;
  Rect? get worldBounds => _worldBounds;

  double _scale = 1;
  double get scale => _scale;

  double _translateX = 0;
  double get translateX => _translateX;

  double _translateY = 0;
  double get translateY => _translateY;

  _UpdateRequest? _lastUpdateRequest;

  /// Matrix to be used to convert world coordinates to canvas coordinates.
  Matrix4 _worldToCanvas = VectorMapController._buildMatrix4();
  Matrix4 get worldToCanvas => _worldToCanvas;

  /// Matrix to be used to convert canvas coordinates to world coordinates.
  Matrix4 _canvasToWorld = VectorMapController._buildMatrix4();
  Matrix4 get canvasToWorld => _canvasToWorld;

  MapDebugger? _debugger;

  @internal
  void setLastCanvasSize(Size canvasSize) {
    this.canvasSize = canvasSize;
  }

  void setLayers(List<MapLayer> layers) {
    this._worldBounds = MapLayer.boundsOf(layers);
    int chunksCount = 0;
    for (MapLayer layer in layers) {
      DrawableLayer drawableLayer = DrawableLayer(layer);
      _drawableLayers.add(drawableLayer);
      chunksCount += drawableLayer.chunks.length;
    }
    _debugger?.initialize(layers, chunksCount);
  }

  void setDebugger(MapDebugger? debugger) {
    _debugger = debugger;
  }

  void translate(double translateX, double translateY) {
    _translateX = translateX;
    _translateY = translateY;
    _buildMatrices4();
  }

  void fit() {
    if (canvasSize != null) {
      _fit(canvasSize!);
    }
  }

  void _fit(Size canvasSize) {
    _scale = 1;
    _translateX = 0;
    _translateY = 0;

    if (_worldBounds != null && canvasSize.isEmpty == false) {
      double scaleX = canvasSize.width / _worldBounds!.width;
      double scaleY = canvasSize.height / _worldBounds!.height;
      _scale = math.min(scaleX, scaleY);

      _translateX =
          (canvasSize.width / 2.0) - (_scale * _worldBounds!.center.dx);
      _translateY =
          (canvasSize.height / 2.0) + (_scale * _worldBounds!.center.dy);
    }
    _buildMatrices4();
  }

  void zoom(Offset canvasLocation, bool zoomIn) {
    if (canvasSize != null) {
      _zoom(canvasSize!, canvasLocation, zoomIn);
    }
  }

  void _zoom(Size canvasSize, Offset canvasLocation, bool zoomIn) {
    double zoom = 1;
    if (zoomIn) {
      zoom = 1.05;
    } else {
      zoom = 0.95;
    }
    double newScale = _scale * zoom;
    Offset refInWorld =
        MatrixUtils.transformPoint(_canvasToWorld, canvasLocation);
    _translateX = canvasLocation.dx - (refInWorld.dx * newScale);
    _translateY = canvasLocation.dy + (refInWorld.dy * newScale);
    _scale = _scale * zoom;
    _buildMatrices4();
  }

  void _buildMatrices4() {
    _worldToCanvas = VectorMapController._buildMatrix4();
    _worldToCanvas.translate(_translateX, _translateY, 0);
    _worldToCanvas.scale(_scale, -_scale, 1);

    _canvasToWorld = Matrix4.inverted(_worldToCanvas);
  }

  void cancelUpdate() {
    _lastUpdateRequest?.ignore = true;
  }

  void clearBuffers() {
    for (DrawableLayer drawableLayer in _drawableLayers) {
      for (DrawableLayerChunk chunk in drawableLayer.chunks) {
        chunk.buffer = null;
      }
    }
  }

  void updateDrawableFeatures(
      {required Size canvasSize, required double contourThickness}) {
    _firstUpdate = false;
    _UpdateRequest updateRequest = _UpdateRequest(
        canvasSize: canvasSize,
        worldToCanvas: _worldToCanvas,
        scale: _scale,
        translateX: _translateX,
        translateY: _translateY,
        contourThickness: contourThickness);
    if (_lastUpdateRequest != null) {
      _lastUpdateRequest!.ignore = true;
      _lastUpdateRequest!.next = updateRequest;
    } else {
      _lastUpdateRequest = updateRequest;
      _updateDrawableFeatures(updateRequest);
    }
  }

  Future<void> _updateDrawableFeatures(_UpdateRequest updateRequest) async {
    int pointsCount = 0;
    _debugger?.bufferBuildDuration.clear();
    _debugger?.drawableBuildDuration.clear();
    _debugger?.updateSimplifiedPointsCount(pointsCount);
    for (DrawableLayer drawableLayer in _drawableLayers) {
      if (updateRequest.ignore) {
        break;
      }
      MapLayer layer = drawableLayer.layer;
      MapTheme theme = layer.theme;
      MapDataSource dataSource = layer.dataSource;

      for (DrawableLayerChunk chunk in drawableLayer.chunks) {
        if (updateRequest.ignore) {
          break;
        }
        for (int index = 0; index < chunk.length; index++) {
          if (updateRequest.ignore) {
            break;
          }
          DrawableFeature drawableFeature = chunk.getDrawableFeature(index);
          _debugger?.drawableBuildDuration.open();
          drawableFeature.drawable = DrawableBuilder.build(
              dataSource: dataSource,
              feature: drawableFeature.feature,
              theme: theme,
              worldToCanvas: updateRequest.worldToCanvas,
              scale: updateRequest.scale,
              simplifier: IntegerSimplifier());
          _debugger?.drawableBuildDuration.closeAndInc();
          pointsCount += drawableFeature.drawable!.pointsCount;
          _debugger?.updateSimplifiedPointsCount(pointsCount);
        }
        _debugger?.bufferBuildDuration.open();
        chunk.buffer = await _createBuffer(
            chunk: chunk,
            layer: drawableLayer.layer,
            canvasSize: updateRequest.canvasSize,
            contourThickness: updateRequest.contourThickness);
        _debugger?.bufferBuildDuration.closeAndInc();
        notifyListeners();
        await Future.delayed(Duration.zero);
      }
    }
    if (updateRequest.ignore) {
      clearBuffers();
    }
    if (updateRequest.next != null) {
      _lastUpdateRequest = updateRequest.next;
      _updateDrawableFeatures(_lastUpdateRequest!);
    } else {
      _lastUpdateRequest = null;
    }
  }

  Future<ui.Image> _createBuffer(
      {required DrawableLayerChunk chunk,
      required MapLayer layer,
      required Size canvasSize,
      required double contourThickness}) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(
        recorder,
        Rect.fromPoints(
            Offset.zero, Offset(canvasSize.width, canvasSize.height)));

    canvas.save();
    applyMatrixOn(canvas);

    DrawUtils.draw(
        canvas: canvas,
        chunk: chunk,
        layer: layer,
        contourThickness: contourThickness,
        scale: _scale,
        antiAlias: true);

    canvas.restore();

    ui.Picture picture = recorder.endRecording();
    return picture.toImage(canvasSize.width.ceil(), canvasSize.height.ceil());
  }

  Future<MemoryImage> toMemoryImageProvider(ui.Image image) async {
    ByteData? imageByteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List uint8list = imageByteData!.buffer.asUint8List();
    return MemoryImage(uint8list);
  }

  /// Applies a matrix on the canvas.
  void applyMatrixOn(Canvas canvas) {
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

class _UpdateRequest {
  _UpdateRequest(
      {required this.canvasSize,
      required this.contourThickness,
      required this.scale,
      required this.translateX,
      required this.translateY,
      required this.worldToCanvas});

  final Size canvasSize;
  final double contourThickness;
  final double scale;
  final double translateX;
  final double translateY;
  final Matrix4 worldToCanvas;
  bool ignore = false;
  _UpdateRequest? next;
}
