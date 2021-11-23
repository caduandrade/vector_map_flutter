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
import 'package:vector_map/src/vector_map_mode.dart';

class VectorMapController extends ChangeNotifier implements VectorMapApi {
  /// The default [contourThickness] value is 1.
  VectorMapController(
      {List<MapLayer>? layers,
      this.contourThickness = 1,
      this.delayToRefreshResolution = 1000,
      VectorMapMode mode = VectorMapMode.panAndZoom,
      this.debugger,
      this.maxScale = 30000,
      this.minScale = 0.1})
      : this._mode = mode,
        this._scale = minScale {
    layers?.forEach((layer) => _addLayer(layer));
    _afterLayersChange();
    debugger?.updateMode(mode);
    if (this.maxScale <= this.minScale) {
      throw new ArgumentError('maxScale must be bigger than minScale');
    }
  }

  VectorMapMode _mode;
  VectorMapMode get mode => _mode;
  set mode(VectorMapMode mode) {
    if (_mode != mode) {
      _mode = mode;
      if (mode == VectorMapMode.autoFit) {
        fit();
      }
      debugger?.updateMode(mode);
    }
  }

  _UpdateState _updateState = _UpdateState.stopped;

  final HashMap<int, MapLayer> _layerIdAndLayer = HashMap<int, MapLayer>();
  final List<DrawableLayer> _drawableLayers = [];

  bool _rebuildSimplifiedGeometry = true;

  Size? _lastCanvasSize;
  Size? get lastCanvasSize => _lastCanvasSize;

  /// Represents the bounds of all layers.
  Rect? _worldBounds;
  Rect? get worldBounds => _worldBounds;

  double zoomFactor = 0.1;

  final double maxScale;
  final double minScale;

  double _scale;
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

  bool _drawBuffers = false;
  bool get drawBuffers => _drawBuffers;

  int _currentDrawablesUpdateTicket = 0;

  final double contourThickness;

  final int delayToRefreshResolution;

  final MapDebugger? debugger;

  void addLayer(MapLayer layer) {
    _addLayer(layer);
    _afterLayersChange();
    notifyListeners();
  }

  void _addLayer(MapLayer layer) {
    if (_layerIdAndLayer.containsKey(layer.id)) {
      throw VectorMapError('Duplicated layer id: ' + layer.id.toString());
    }
    _layerIdAndLayer[layer.id] = layer;
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

  MapLayer getLayerByIndex(int index) {
    if (index >= 0 && index < _drawableLayers.length) {
      return _drawableLayers[index].layer;
    }
    throw VectorMapError('Invalid layer index: $index');
  }

  MapLayer getLayerById(int id) {
    MapLayer? layer = _layerIdAndLayer[id];
    if (layer == null) {
      throw VectorMapError('Invalid layer id: $id');
    }
    return layer;
  }

  bool hasLayerId(int id) {
    return _layerIdAndLayer.containsKey(id);
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
  void notifyPanMode({required bool start}) {
    if (start) {
      _drawBuffers = false;
      // cancel running update
      _cancelDrawablesUpdate();
      // cancel scheduled update
      _nextDrawablesUpdateTicket();
    } else {
      // schedule the drawables build
      _scheduleDrawablesUpdate(delayed: true);
    }
  }

  @internal
  void setCanvasSize(Size canvasSize) {
    if (_lastCanvasSize != canvasSize) {
      _rebuildSimplifiedGeometry = _lastCanvasSize != canvasSize;
      bool first = _lastCanvasSize == null;
      bool needFit = (first ||
          (_mode == VectorMapMode.autoFit && _rebuildSimplifiedGeometry));
      _lastCanvasSize = canvasSize;
      if (needFit) {
        _fit(canvasSize);
      }

      _drawBuffers = false;
      _cancelDrawablesUpdate();
      if (first) {
        // first build without delay
        _scheduleDrawablesUpdate(delayed: false);
      } else {
        // schedule the drawables build
        _scheduleDrawablesUpdate(delayed: true);
      }
    }
  }

  void translate(double translateX, double translateY) {
    _drawBuffers = false;
    _translateX = translateX;
    _translateY = translateY;
    _buildMatrices4();
    notifyListeners();
  }

  void fit() {
    if (_lastCanvasSize != null) {
      _fit(_lastCanvasSize!);
      _drawBuffers = false;
      _scheduleDrawablesUpdate(delayed: true);
      notifyListeners();
    }
  }

  double _limitScale(double scale) {
    scale = math.max(minScale, scale);
    return math.min(maxScale, scale);
  }

  void _fit(Size canvasSize) {
    if (_worldBounds != null && canvasSize.isEmpty == false) {
      double scaleX = canvasSize.width / _worldBounds!.width;
      double scaleY = canvasSize.height / _worldBounds!.height;
      _scale = _limitScale(math.min(scaleX, scaleY));
      _translateX =
          (canvasSize.width / 2.0) - (_scale * _worldBounds!.center.dx);
      _translateY =
          (canvasSize.height / 2.0) + (_scale * _worldBounds!.center.dy);
      _buildMatrices4();
    }
  }

  void zoomOnCenter(bool zoomIn) {
    if (_lastCanvasSize != null) {
      _zoom(
          _lastCanvasSize!,
          Offset(_lastCanvasSize!.width / 2, _lastCanvasSize!.height / 2),
          zoomIn);
    }
  }

  void zoomOnLocation(Offset locationOnCanvas, bool zoomIn) {
    if (_lastCanvasSize != null) {
      _zoom(_lastCanvasSize!, locationOnCanvas, zoomIn);
    }
  }

  void _zoom(Size canvasSize, Offset locationOnCanvas, bool zoomIn) {
    _drawBuffers = false;
    _cancelDrawablesUpdate();
    _rebuildSimplifiedGeometry = true;
    double zoom = 1;
    if (zoomIn) {
      zoom += zoomFactor;
    } else {
      zoom -= zoomFactor;
    }
    double newScale = _limitScale(_scale * zoom);
    Offset refInWorld =
        MatrixUtils.transformPoint(_canvasToWorld, locationOnCanvas);
    _translateX = locationOnCanvas.dx - (refInWorld.dx * newScale);
    _translateY = locationOnCanvas.dy + (refInWorld.dy * newScale);
    _scale = newScale;
    _buildMatrices4();
    // schedule the drawables build
    _scheduleDrawablesUpdate(delayed: true);
    notifyListeners();
  }

  void _buildMatrices4() {
    _worldToCanvas = VectorMapController._buildMatrix4();
    _worldToCanvas.translate(_translateX, _translateY, 0);
    _worldToCanvas.scale(_scale, -_scale, 1);

    _canvasToWorld = Matrix4.inverted(_worldToCanvas);
  }

  void _cancelDrawablesUpdate() {
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

  int _nextDrawablesUpdateTicket() {
    _currentDrawablesUpdateTicket++;
    if (_currentDrawablesUpdateTicket == 999999) {
      _currentDrawablesUpdateTicket = 0;
    }
    return _currentDrawablesUpdateTicket;
  }

  void _scheduleDrawablesUpdate({required bool delayed}) {
    if (delayed) {
      int ticket = _nextDrawablesUpdateTicket();
      Future.delayed(Duration(milliseconds: delayToRefreshResolution),
          () => _startDrawablesUpdate(ticket: ticket));
    } else {
      Future.microtask(
          () => _startDrawablesUpdate(ticket: _currentDrawablesUpdateTicket));
    }
  }

  void _startDrawablesUpdate({required int ticket}) {
    if (_currentDrawablesUpdateTicket == ticket) {
      if (_lastCanvasSize != null) {
        _clearBuffers();
        if (_updateState == _UpdateState.stopped) {
          _updateDrawables();
        } else {
          _updateState = _UpdateState.restarting;
        }
      }
      _drawBuffers = true;
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
            if (_rebuildSimplifiedGeometry) {
              debugger?.drawableBuildDuration.open();
              drawableFeature.drawable = DrawableBuilder.build(
                  dataSource: dataSource,
                  feature: drawableFeature.feature,
                  theme: theme,
                  worldToCanvas: _worldToCanvas,
                  scale: _scale,
                  simplifier: IntegerSimplifier());
              debugger?.drawableBuildDuration.closeAndInc();
            }
            if (drawableFeature.drawable != null) {
              pointsCount += drawableFeature.drawable!.pointsCount;
            }
            debugger?.updateSimplifiedPointsCount(pointsCount);
          }
          if (_updateState != _UpdateState.running) {
            break;
          }

          if (_lastCanvasSize != null) {
            Rect canvasInWorld = MatrixUtils.transformRect(
                _canvasToWorld,
                Rect.fromLTWH(
                    0, 0, _lastCanvasSize!.width, _lastCanvasSize!.height));
            if (chunk.bounds != null && chunk.bounds!.overlaps(canvasInWorld)) {
              debugger?.bufferBuildDuration.open();
              chunk.buffer = await _createBuffer(
                  chunk: chunk,
                  layer: drawableLayer.layer,
                  canvasSize: _lastCanvasSize!);
              debugger?.bufferBuildDuration.closeAndInc();
            }
          }
          if (_updateState == _UpdateState.running) {
            notifyListeners();
          }
          await Future.delayed(Duration.zero);
        }
      }
      if (_updateState == _UpdateState.running) {
        _updateState = _UpdateState.stopped;
        _rebuildSimplifiedGeometry = false;
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
