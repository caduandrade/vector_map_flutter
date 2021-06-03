import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/debugger.dart';
import 'package:vector_map/src/layer.dart';
import 'package:vector_map/src/matrix.dart';
import 'package:vector_map/src/paintable.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme.dart';

enum _State { waiting, running, stopped }

/// Event to signal that a map resolution has been created.
typedef OnFinish = Function(MapResolution newMapResolution);

/// Representation of the map in a given resolution. Stores simplified
/// paths and an image buffer.
class MapResolution {
  MapResolution._(
      {required this.widgetSize,
      required this.paintableLayers,
      required this.layerBuffers,
      required this.pointsCount});

  final Size widgetSize;
  final UnmodifiableListView<PaintableLayer> paintableLayers;
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
  final List<PaintableLayer> _paintableLayers = [];
  final List<Image> _layerBuffers = [];

  final MapDebugger? debugger;

  _State _state = _State.waiting;

  stop() {
    _state = _State.stopped;
  }

  start() async {
    if (_state == _State.waiting) {
      debugger?.clearCountPaintableBuildDuration();
      debugger?.clearCountBufferBuildDuration();
      _state = _State.running;

      _paintableLayers.clear();
      _layerBuffers.clear();

      int pointsCount = 0;
      for (MapLayer layer in layers) {
        MapDataSource dataSource = layer.dataSource;
        MapTheme theme = layer.theme;

        Map<int, PaintableFeature> paintableFeatures =
            Map<int, PaintableFeature>();

        for (MapFeature feature in dataSource.features.values) {
          if (_state == _State.stopped) {
            return;
          }
          debugger?.markPaintableBuildStart();
          PaintableFeature paintableFeature = feature.geometry
              .toPaintableFeature(theme, canvasMatrix, simplifier);
          debugger?.markPaintableBuildEnd();
          pointsCount += paintableFeature.pointsCount;
          paintableFeatures[feature.id] = paintableFeature;
        }
        PaintableLayer paintableLayer =
            PaintableLayer(layer, paintableFeatures);
        debugger?.markBufferBuildStart();
        Image image = await _createBuffer(canvasMatrix, paintableLayer);
        debugger?.markBufferBuildEnd();
        _paintableLayers.add(paintableLayer);
        _layerBuffers.add(image);
      }
      if (_state != _State.stopped) {
        debugger?.updateCountPaintableBuildDuration();
        debugger?.updateCountBufferBuildDuration();

        onFinish(MapResolution._(
            widgetSize: canvasMatrix.widgetSize,
            paintableLayers: UnmodifiableListView(_paintableLayers),
            layerBuffers: UnmodifiableListView(_layerBuffers),
            pointsCount: pointsCount));
      }
    }
  }

  Future<Image> _createBuffer(
      CanvasMatrix canvasMatrix, PaintableLayer paintableLayer) async {
    PictureRecorder recorder = PictureRecorder();
    Canvas canvas = new Canvas(
        recorder,
        new Rect.fromPoints(
            Offset.zero,
            Offset(canvasMatrix.widgetSize.width,
                canvasMatrix.widgetSize.height)));

    canvas.save();
    canvasMatrix.applyOn(canvas);

    paintableLayer.drawOn(
        canvas: canvas,
        contourThickness: contourThickness,
        scale: canvasMatrix.scale,
        antiAlias: true);

    canvas.restore();

    Picture picture = recorder.endRecording();
    return await picture.toImage(canvasMatrix.widgetSize.width.toInt(),
        canvasMatrix.widgetSize.height.toInt());
  }
}
