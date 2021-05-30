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

/// Event to signal that a map resolution has been created.
typedef OnFinish(MapResolution newMapResolution);

/// Representation of the map in a given resolution. Stores simplified
/// paths and an image buffer.
class MapResolution {
  MapResolution._(
      {required this.widgetSize,
      required this.bufferWidth,
      required this.bufferHeight,
      required this.paintableLayers,
      required this.pointsCount});

  final Size widgetSize;
  final int bufferWidth;
  final int bufferHeight;
  final UnmodifiableListView<PaintableLayer> paintableLayers;
  final int pointsCount;

  Future<MemoryImage> toMemoryImageProvider(Image image) async {
    ByteData? imageByteData =
        await image.toByteData(format: ImageByteFormat.png);
    Uint8List uint8list = imageByteData!.buffer.asUint8List();
    return MemoryImage(uint8list);
  }
}

/// Holds a geometry to be paint in the current resolution.
class PaintableGeometry {
  PaintableGeometry._(this._path, this._offset, this._pointBounds, this._radius,
      this.pointsCount);

  factory PaintableGeometry.path(Path path, int pointsCount) {
    return PaintableGeometry._(path, null, null, null, pointsCount);
  }

  factory PaintableGeometry.circle(Offset offset, double radius) {
    return PaintableGeometry._(
        null,
        offset,
        Rect.fromLTWH(
            offset.dx - radius, offset.dy - radius, radius * 2, radius * 2),
        radius,
        1);
  }

  final Path? _path;

  final Offset? _offset;
  final Rect? _pointBounds;
  final double? _radius;

  final int pointsCount;

  /// Gets the geometry bounds
  Rect getBounds() {
    if (_path != null) {
      return _path!.getBounds();
    } else if (_pointBounds != null) {
      return _pointBounds!;
    }
    throw VectorMapError('Illegal PaintableGeometry');
  }

  /// Checks whether a point is contained in the geometry.
  bool contains(Offset offset) {
    if (_path != null) {
      return _path!.contains(offset);
    } else if (_pointBounds != null) {
      return _pointBounds!.contains(offset);
    }
    return false;
  }

  /// Draws the geometry.
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

/// Holds all geometry layers to be paint in the current resolution.
class PaintableLayer {
  PaintableLayer(this.layer, this.layerBuffer, this.paintableGeometries);

  final MapLayer layer;
  final Image layerBuffer;
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
        Map<int, Color> colors = Map<int, Color>();
        for (MapFeature feature in dataSource.features.values) {
          if (_state == _State.stopped) {
            return;
          }
          colors[feature.id] =
              MapTheme.getThemeOrDefaultColor(dataSource, feature, theme);
          PaintableGeometry paintableGeometry = feature.geometry
              .toPaintableGeometry(mapMatrices.canvasMatrix, simplifier);
          pointsCount += paintableGeometry.pointsCount;
          paintableGeometries[feature.id] = paintableGeometry;
        }
        Image? layerBuffer =
            await _createBuffer(layer, paintableGeometries, colors);
        if (layerBuffer == null) {
          return;
        }
        _paintableLayers
            .add(PaintableLayer(layer, layerBuffer, paintableGeometries));
      }
      if (_state != _State.stopped) {
        onFinish(MapResolution._(
            widgetSize: mapMatrices.canvasMatrix.widgetSize,
            bufferWidth: mapMatrices.bufferCreationMatrix.imageWidth.toInt(),
            bufferHeight: mapMatrices.bufferCreationMatrix.imageHeight.toInt(),
            paintableLayers: UnmodifiableListView(_paintableLayers),
            pointsCount: pointsCount));
      }
    }
  }

  Future<Image?> _createBuffer(
      MapLayer layer,
      Map<int, PaintableGeometry> paintableGeometries,
      Map<int, Color> colors) async {
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

    for (int featureId in paintableGeometries.keys) {
      PaintableGeometry paintableGeometry = paintableGeometries[featureId]!;
      Color color = colors[featureId]!;
      if (_state == _State.stopped) {
        return null;
      }

      var paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color
        ..isAntiAlias = true;
      paintableGeometry.draw(canvas, paint);
    }

    if (contourThickness > 0) {
      MapTheme theme = layer.theme;
      var paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = theme.contourColor != null
            ? theme.contourColor!
            : MapTheme.defaultContourColor
        ..strokeWidth = contourThickness / bufferCreationMatrix.scale
        ..isAntiAlias = true;
      for (PaintableGeometry paintableGeometry in paintableGeometries.values) {
        if (_state == _State.stopped) {
          return null;
        }
        paintableGeometry.draw(canvas, paint);
      }
    }

    canvas.restore();

    Picture picture = recorder.endRecording();
    return await picture.toImage(bufferCreationMatrix.imageWidth.toInt(),
        bufferCreationMatrix.imageHeight.toInt());
  }
}
