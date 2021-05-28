import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/layer.dart';
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
      required this.paintableLayers,
      required this.pointsCount});

  final Size widgetSize;
  final Image mapBuffer;
  final UnmodifiableListView<PaintableLayer> paintableLayers;
  final int pointsCount;

  Future<MemoryImage> toMemoryImageProvider() async {
    ByteData? imageByteData =
        await mapBuffer.toByteData(format: ImageByteFormat.png);
    Uint8List uint8list = imageByteData!.buffer.asUint8List();
    return MemoryImage(uint8list);
  }
}

class PaintableGeometry {
  PaintableGeometry._(this._path, this._offset, this._pointBounds, this._radius,
      this.pointsCount, this.color);

  factory PaintableGeometry.path(Path path, int pointsCount, Color color) {
    return PaintableGeometry._(path, null, null, null, pointsCount, color);
  }

  factory PaintableGeometry.circle(Offset offset, double radius, Color color) {
    return PaintableGeometry._(
        null,
        offset,
        Rect.fromLTWH(
            offset.dx - radius / 2, offset.dy - radius / 2, radius, radius),
        radius,
        1,
        color);
  }

  final Path? _path;

  final Offset? _offset;
  final Rect? _pointBounds;
  final double? _radius;

  final Color color;
  final int pointsCount;

  Rect getBounds() {
    if (_path != null) {
      return _path!.getBounds();
    } else if (_pointBounds != null) {
      return _pointBounds!;
    }
    throw VectorMapError('Illegal PaintableGeometry');
  }

  bool contains(Offset offset) {
    if (_path != null) {
      return _path!.contains(offset);
    } else if (_pointBounds != null) {
      return _pointBounds!.contains(offset);
    }
    return false;
  }

  draw(Canvas canvas, Paint paint) {
    if (_path != null) {
      canvas.drawPath(_path!, paint);
    } else if (_offset != null && _radius != null) {
      canvas.drawCircle(_offset!, _radius!, paint);
    } else {
      throw VectorMapError('Illegal PaintableGeometry');
    }
  }
}

class PaintableLayer {
  PaintableLayer(this.layer, this.paintableGeometries);

  final MapLayer layer;
  final Map<int, PaintableGeometry> paintableGeometries;
}

/// [MapResolution] builder.
class MapResolutionBuilder {
  MapResolutionBuilder(
      {required this.layers,
      required this.contourThickness,
      required this.mapMatrices,
      required this.simplifier,
      required this.onFinish});

  final List<MapLayer> layers;
  final double contourThickness;
  final MapMatrices mapMatrices;
  final GeometrySimplifier simplifier;

  final OnFinish onFinish;
  final List<PaintableLayer> _paintableLayers = [];

  _State _state = _State.waiting;

  stop() {
    _state = _State.stopped;
  }

  start() async {
    if (_state == _State.waiting) {
      _state = _State.running;

      _paintableLayers.clear();

      int pointsCount = 0;
      for (MapLayer layer in layers) {
        MapDataSource dataSource = layer.dataSource;
        MapTheme theme = layer.theme;
        Map<int, PaintableGeometry> paintableGeometries =
            Map<int, PaintableGeometry>();
        for (MapFeature feature in dataSource.features.values) {
          if (_state == _State.stopped) {
            return;
          }
          Color color =
              MapTheme.getThemeOrDefaultColor(dataSource, feature, theme);
          MapGeometry geometry = feature.geometry;
          PaintableGeometry paintableGeometry = geometry.toPaintableGeometry(
              mapMatrices.canvasMatrix, simplifier, color);
          pointsCount += paintableGeometry.pointsCount;
          paintableGeometries[feature.id] = paintableGeometry;
        }
        _paintableLayers.add(PaintableLayer(layer, paintableGeometries));
      }
      _createBuffer(pointsCount);
    }
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

    for (PaintableLayer paintableLayer in _paintableLayers) {
      for (PaintableGeometry paintableGeometry
          in paintableLayer.paintableGeometries.values) {
        if (_state == _State.stopped) {
          return;
        }
        var paint = Paint()
          ..style = PaintingStyle.fill
          ..color = paintableGeometry.color
          ..isAntiAlias = true;
        paintableGeometry.draw(canvas, paint);
      }
    }

    if (contourThickness > 0) {
      for (PaintableLayer paintableLayer in _paintableLayers) {
        MapTheme theme = paintableLayer.layer.theme;
        var paint = Paint()
          ..style = PaintingStyle.stroke
          ..color = theme.contourColor != null
              ? theme.contourColor!
              : MapTheme.defaultContourColor
          ..strokeWidth = contourThickness / bufferCreationMatrix.scale
          ..isAntiAlias = true;
        for (PaintableGeometry paintableGeometry
            in paintableLayer.paintableGeometries.values) {
          if (_state == _State.stopped) {
            return;
          }
          paintableGeometry.draw(canvas, paint);
        }
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
          paintableLayers: UnmodifiableListView(_paintableLayers),
          pointsCount: pointsCount,
          mapBuffer: mapBuffer));
    }
  }
}
