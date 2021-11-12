import 'dart:collection';
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
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/map_highlight.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme/map_theme.dart';
import 'package:vector_map/src/vector_map_api.dart';

class VectorMapController extends ChangeNotifier implements VectorMapApi {
  /// The default [contourThickness] value is 1.
  VectorMapController(
      {List<MapLayer>? layers,
      this.contourThickness = 1,
      this.delayToRefreshResolution = 1000,
      bool debuggerEnabled = false})
      : this.debugger = debuggerEnabled ? MapDebugger() : null {
    layers?.forEach((layer) => _addLayer(layer));
    _afterLayersChange();
  }

  _UpdateState _updateState = _UpdateState.stopped;

  final HashSet<int> _drawableLayerIds = HashSet<int>();
  final List<DrawableLayer> _drawableLayers = [];

  Size? _lastCanvasSize;
  Size? get lastCanvasSize => _lastCanvasSize;

  /// Represents the bounds of all layers.
  Rect? _worldBounds;
  Rect? get worldBounds => _worldBounds;

  double _scale = 1;
  double get scale => _scale;

  double _translateX = 0;
  double get translateX => _translateX;

  double _translateY = 0;
  double get translateY => _translateY;

  /// Matrix to be used to convert world coordinates to canvas coordinates.
  Matrix4 _worldToCanvas = VectorMapController._buildMatrix4();
  Matrix4 get worldToCanvas => _worldToCanvas;

  /// Matrix to be used to convert canvas coordinates to world coordinates.
  Matrix4 _canvasToWorld = VectorMapController._buildMatrix4();
  Matrix4 get canvasToWorld => _canvasToWorld;

  MapHighlight? _highlight;
  MapHighlight? get highlight => _highlight;

  double zoomFactor = 0.1;

  final double contourThickness;

  final int delayToRefreshResolution;

  final MapDebugger? debugger;

  void addLayer(MapLayer layer) {
    _addLayer(layer);
    _afterLayersChange();
    //TODO notify?
  }

  void _addLayer(MapLayer layer) {
    if (_drawableLayerIds.add(layer.id) == false) {
      throw VectorMapError('Duplicated layer id: ' + layer.id.toString());
    }
    _drawableLayers.add(DrawableLayer(layer));
  }

  void _afterLayersChange() {
    this._worldBounds = DrawableLayer.boundsOf(_drawableLayers);
    int chunksCount = 0;
    _drawableLayers
        .forEach((drawableLayer) => chunksCount += drawableLayer.chunks.length);
    debugger?.updateLayers(_drawableLayers, chunksCount);
  }

  int get layersCount {
    return _drawableLayers.length;
  }

  bool get hasLayer {
    return _drawableLayers.isNotEmpty;
  }

  MapLayer getLayer(int index) {
    if (index > 0 && _drawableLayers.length < index) {
      return _drawableLayers[index].layer;
    }
    throw VectorMapError('Invalid layer index: $index');
  }

  bool get hoverDrawable {
    for (DrawableLayer drawableLayer in _drawableLayers) {
      if (drawableLayer.layer.hoverDrawable) {
        return true;
      }
    }
    return false;
  }

  DrawableLayer getDrawableLayer(int index) {
    return _drawableLayers[index];
  }

  @override
  void clearHighlight() {
    _highlight = null;
    if (hoverDrawable) {
      notifyListeners();
    }
  }

  @override
  void setHighlight(MapHighlight newHighlight) {
    _highlight = newHighlight;
    if (hoverDrawable) {
      notifyListeners();
    }
  }

  @internal
  bool setCanvasSize(Size canvasSize) {
    bool first = _lastCanvasSize == null;
    _lastCanvasSize = canvasSize;
    if (first) {
      _fit(canvasSize);
    }
    return first;
  }

  void translate(double translateX, double translateY) {
    _translateX = translateX;
    _translateY = translateY;
    _buildMatrices4();
    notifyListeners();
  }

  void fit() {
    if (_lastCanvasSize != null) {
      _fit(_lastCanvasSize!);
      updateDrawables();
      notifyListeners();
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
    if (_lastCanvasSize != null) {
      _zoom(_lastCanvasSize!, canvasLocation, zoomIn);
      notifyListeners();
    }
  }

  void _zoom(Size canvasSize, Offset canvasLocation, bool zoomIn) {
    double zoom = 1;
    if (zoomIn) {
      zoom += zoomFactor;
    } else {
      zoom -= zoomFactor;
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

  @internal
  void cancelDrawablesUpdate() {
    if (_updateState != _UpdateState.stopped) {
      _updateState = _UpdateState.canceling;
    }
  }

  void _clearBuffers() {
    for (DrawableLayer drawableLayer in _drawableLayers) {
      for (DrawableLayerChunk chunk in drawableLayer.chunks) {
        chunk.buffer = null;
      }
    }
  }

  @internal
  void updateDrawables() {
    if (_lastCanvasSize != null) {
      _clearBuffers();
      if (_updateState == _UpdateState.stopped) {
        _updateDrawables();
      } else {
        _updateState = _UpdateState.restarting;
      }
    }
  }

  Future<void> _updateDrawables() async {
    _updateState = _UpdateState.running;
    while (_updateState == _UpdateState.running) {
      int pointsCount = 0;
      debugger?.bufferBuildDuration.clear();
      debugger?.drawableBuildDuration.clear();
      debugger?.updateSimplifiedPointsCount(pointsCount);
      for (DrawableLayer drawableLayer in _drawableLayers) {
        if (_updateState != _UpdateState.running) {
          break;
        }
        MapLayer layer = drawableLayer.layer;
        MapTheme theme = layer.theme;
        MapDataSource dataSource = layer.dataSource;

        for (DrawableLayerChunk chunk in drawableLayer.chunks) {
          if (_updateState != _UpdateState.running) {
            break;
          }
          for (int index = 0; index < chunk.length; index++) {
            if (_updateState != _UpdateState.running) {
              break;
            }
            DrawableFeature drawableFeature = chunk.getDrawableFeature(index);
            debugger?.drawableBuildDuration.open();
            drawableFeature.drawable = DrawableBuilder.build(
                dataSource: dataSource,
                feature: drawableFeature.feature,
                theme: theme,
                worldToCanvas: _worldToCanvas,
                scale: _scale,
                simplifier: IntegerSimplifier());
            debugger?.drawableBuildDuration.closeAndInc();
            pointsCount += drawableFeature.drawable!.pointsCount;
            debugger?.updateSimplifiedPointsCount(pointsCount);
          }
          if (_updateState != _UpdateState.running) {
            break;
          }
          if (_lastCanvasSize != null) {
            debugger?.bufferBuildDuration.open();
            chunk.buffer = await _createBuffer(
                chunk: chunk,
                layer: drawableLayer.layer,
                canvasSize: _lastCanvasSize!);
            debugger?.bufferBuildDuration.closeAndInc();
          }
          if (_updateState == _UpdateState.running) {
            notifyListeners();
          }
          await Future.delayed(Duration.zero);
        }
      }
      if (_updateState == _UpdateState.running) {
        _updateState = _UpdateState.stopped;
      } else if (_updateState == _UpdateState.canceling) {
        _clearBuffers();
        _updateState = _UpdateState.stopped;
      } else if (_updateState == _UpdateState.restarting) {
        _clearBuffers();
        _updateState = _UpdateState.running;
      }
    }
  }

  Future<ui.Image> _createBuffer(
      {required DrawableLayerChunk chunk,
      required MapLayer layer,
      required Size canvasSize}) async {
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

enum _UpdateState { stopped, running, canceling, restarting }
