import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/matrices.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme.dart';

enum _State { waiting, running, stopped }

typedef OnFinish(MapResolution newMapResolution);

/// Representation of the map in a given resolution. Stores simplified
/// paths and an image buffer.
class MapResolution {
  MapResolution._(
      {required this.widgetSize,
      required this.mapBuffer,
      required this.paths,
      required this.pointsCount});

  final Size widgetSize;
  final Image mapBuffer;
  final UnmodifiableMapView<int, Path> paths;
  final int pointsCount;

  Future<MemoryImage> toMemoryImageProvider() async {
    ByteData? imageByteData =
        await mapBuffer.toByteData(format: ImageByteFormat.png);
    Uint8List uint8list = imageByteData!.buffer.asUint8List();
    return MemoryImage(uint8list);
  }
}

/// [MapResolution] builder.
class MapResolutionBuilder {
  MapResolutionBuilder(
      {required this.dataSource,
      required this.theme,
      required this.contourThickness,
      required this.mapMatrices,
      required this.simplifier,
      required this.onFinish});

  final VectorMapDataSource dataSource;
  final VectorMapTheme theme;
  final double contourThickness;
  final MapMatrices mapMatrices;
  final GeometrySimplifier simplifier;

  final OnFinish onFinish;
  final Map<int, Path> _paths = Map<int, Path>();
  final Map<int, Color> _colors = Map<int, Color>();

  _State _state = _State.waiting;
  Map<int, MapFeature> _pendingFeatures = Map<int, MapFeature>();

  stop() {
    _state = _State.stopped;
  }

  start() async {
    if (_state == _State.waiting) {
      _state = _State.running;
      _pendingFeatures.addAll(dataSource.features);
      _nextPath();
    }
  }

  _nextPath() async {
    if (_state == _State.stopped) {
      return;
    }

    int pointsCount = 0;
    while (_pendingFeatures.length > 0) {
      final int id = _pendingFeatures.keys.first;
      final MapFeature feature = _pendingFeatures.remove(id)!;
      MapGeometry geometry = feature.geometry;
      SimplifiedPath simplifiedPath =
          geometry.toPath(mapMatrices.canvasMatrix, simplifier);
      pointsCount += simplifiedPath.pointsCount;
      _paths[id] = simplifiedPath.path;
      _colors[id] =
          VectorMapTheme.getThemeOrDefaultColor(dataSource, feature, theme);
    }

    _createBuffer(pointsCount);
  }

  _createBuffer(int pointsCount) async {
    BufferCreationMatrix bufferCreationMatrix =
        mapMatrices.bufferCreationMatrix;
    PictureRecorder recorder = PictureRecorder();
    Canvas canvas = new Canvas(
        recorder,
        new Rect.fromPoints(
            Offset.zero,
            Offset(bufferCreationMatrix.imageWidth,
                bufferCreationMatrix.imageHeight)));

    canvas.save();

    canvas.translate(
        bufferCreationMatrix.translateX, bufferCreationMatrix.translateY);
    canvas.scale(bufferCreationMatrix.scale, -bufferCreationMatrix.scale);

    _paths.entries.forEach((element) {
      int id = element.key;
      Path path = element.value;
      if (_state == _State.stopped) {
        return;
      }
      var paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _colors[id]!
        ..isAntiAlias = true;
      canvas.drawPath(path, paint);
    });

    if (contourThickness > 0) {
      var paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = theme.contourColor != null
            ? theme.contourColor!
            : VectorMapTheme.defaultContourColor
        ..strokeWidth = contourThickness / bufferCreationMatrix.scale
        ..isAntiAlias = true;

      for (Path path in _paths.values) {
        if (_state == _State.stopped) {
          return;
        }
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();

    Picture picture = recorder.endRecording();
    Image mapBuffer = await picture.toImage(
        bufferCreationMatrix.imageWidth.toInt(),
        bufferCreationMatrix.imageHeight.toInt());

    if (_state != _State.stopped) {
      onFinish(MapResolution._(
          widgetSize: mapMatrices.canvasMatrix.widgetSize,
          paths: UnmodifiableMapView(_paths),
          pointsCount: pointsCount,
          mapBuffer: mapBuffer));
    }
  }
}
