import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/debugger.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_feature_builder.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/matrix.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme/map_theme.dart';

enum _State { waiting, running, stopped }

/// Event to signal that a map resolution has been created.
typedef OnFinish = Function(MapResolution newMapResolution);

/// Representation of the map in a given resolution.
///
/// Stores simplified paths and an image buffer.
class MapResolution {
  MapResolution._(
      {required this.widgetSize,
      required this.drawableLayers,
      required this.layerBuffers,
      required this.pointsCount});

  final Size widgetSize;
  final UnmodifiableListView<DrawableLayer> drawableLayers;
  final UnmodifiableListView<Image> layerBuffers;
  final int pointsCount;

  Future<MemoryImage> toMemoryImageProvider(Image image) async {
    ByteData? imageByteData =
        await image.toByteData(format: ImageByteFormat.png);
    Uint8List uint8list = imageByteData!.buffer.asUint8List();
    return MemoryImage(uint8list);
  }
}

/// [MapResolution] builder.
class MapResolutionBuilder {
  MapResolutionBuilder(
      {required this.layers,
      required this.contourThickness,
      required this.canvasMatrix,
      required this.simplifier,
      required this.onFinish,
      this.debugger});

  final List<MapLayer> layers;
  final double contourThickness;
  final CanvasMatrix canvasMatrix;
  final GeometrySimplifier simplifier;

  final OnFinish onFinish;
  final List<DrawableLayer> _drawableLayers = [];
  final List<Image> _layerBuffers = [];

  final MapDebugger? debugger;

  _State _state = _State.waiting;

  void stop() {
    _state = _State.stopped;
  }

  void start() async {
    if (_state == _State.waiting) {
      debugger?.openMultiResolutionTime();
      debugger?.clearDrawableBuildDuration();
      debugger?.clearBufferBuildDuration();
      _state = _State.running;

      _drawableLayers.clear();
      _layerBuffers.clear();

      int pointsCount = 0;
      for (MapLayer layer in layers) {
        MapDataSource dataSource = layer.dataSource;
        MapTheme theme = layer.theme;

        Map<int, DrawableFeature> drawableFeatures =
            Map<int, DrawableFeature>();

        for (MapFeature feature in dataSource.features.values) {
          if (_state == _State.stopped) {
            return;
          }
          debugger?.openDrawableBuildDuration();
          DrawableFeature drawableFeature = DrawableFeatureBuilder.build(
              dataSource, feature, theme, canvasMatrix, simplifier);
          debugger?.closeDrawableBuildDuration();
          pointsCount += drawableFeature.pointsCount;
          drawableFeatures[feature.id] = drawableFeature;
        }
        DrawableLayer drawableLayer = DrawableLayer(layer, drawableFeatures);
        debugger?.openBufferBuildDuration();
        Image buffer = await _createBuffer(canvasMatrix, drawableLayer);
        debugger?.closeBufferBuildDuration();
        _drawableLayers.add(drawableLayer);
        _layerBuffers.add(buffer);
      }
      if (_state != _State.stopped) {
        debugger?.updateDrawableBuildDuration();
        debugger?.updateBufferBuildDuration();
        debugger?.closeMultiResolutionTime();

        onFinish(MapResolution._(
            widgetSize: canvasMatrix.canvasSize,
            drawableLayers: UnmodifiableListView(_drawableLayers),
            layerBuffers: UnmodifiableListView(_layerBuffers),
            pointsCount: pointsCount));
      }
    }
  }

  Future<Image> _createBuffer(
      CanvasMatrix canvasMatrix, DrawableLayer drawableLayer) async {
    PictureRecorder recorder = PictureRecorder();
    Canvas canvas = Canvas(
        recorder,
        Rect.fromPoints(
            Offset.zero,
            Offset(canvasMatrix.canvasSize.width,
                canvasMatrix.canvasSize.height)));

    canvas.save();
    canvasMatrix.applyOn(canvas);

    drawableLayer.drawOn(
        canvas: canvas,
        contourThickness: contourThickness,
        scale: canvasMatrix.scale,
        antiAlias: true);

    canvas.restore();

    Picture picture = recorder.endRecording();
    return picture.toImage(canvasMatrix.canvasSize.width.ceil(),
        canvasMatrix.canvasSize.height.ceil());
  }
}
