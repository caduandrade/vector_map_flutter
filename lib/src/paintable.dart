import 'dart:ui';

import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/layer.dart';
import 'package:vector_map/src/matrix.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme.dart';

/// Holds all geometry layers to be paint in the current resolution.
class PaintableLayer {
  PaintableLayer(this.layer, this.paintableFeatures);

  final MapLayer layer;
  final Map<int, PaintableFeature> paintableFeatures;

  drawOn(
      {required Canvas canvas,
      required double contourThickness,
      required double scale,
      required bool antiAlias}) {
    MapDataSource dataSource = layer.dataSource;
    MapTheme theme = layer.theme;

    Map<int, Color> colors = Map<int, Color>();
    for (int id in paintableFeatures.keys) {
      MapFeature feature = dataSource.features[id]!;
      colors[feature.id] =
          MapTheme.getThemeOrDefaultColor(dataSource, feature, theme);
    }

    for (int featureId in paintableFeatures.keys) {
      PaintableFeature paintableFeature = paintableFeatures[featureId]!;
      Color color = colors[featureId]!;

      var paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color
        ..isAntiAlias = antiAlias;
      paintableFeature.drawOn(canvas, paint, scale);
    }

    if (contourThickness > 0) {
      drawContourOn(
          canvas: canvas,
          contourThickness: contourThickness,
          scale: scale,
          antiAlias: antiAlias);
    }
  }

  drawContourOn(
      {required Canvas canvas,
      required double contourThickness,
      required double scale,
      required bool antiAlias}) {
    MapTheme theme = layer.theme;
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = theme.contourColor != null
          ? theme.contourColor!
          : MapTheme.defaultContourColor
      ..strokeWidth = contourThickness / scale
      ..isAntiAlias = antiAlias;
    for (PaintableFeature paintableFeature in paintableFeatures.values) {
      paintableFeature.drawOn(canvas, paint, scale);
    }
  }
}

/// [PaintableFeature] builder.
class PaintableFeatureBuilder {
  static PaintableFeature build(MapFeature feature, MapTheme theme,
      CanvasMatrix canvasMatrix, GeometrySimplifier simplifier) {
    MapGeometry geometry = feature.geometry;
    if (geometry is MapPoint) {
      return _point(geometry, feature, theme, canvasMatrix, simplifier);
    } else if (geometry is MapLinearRing) {
      return _linearRing(geometry, feature, theme, canvasMatrix, simplifier);
    } else if (geometry is MapPolygon) {
      return _polygon(geometry, feature, theme, canvasMatrix, simplifier);
    } else if (geometry is MapMultiPolygon) {
      return _multiPolygon(geometry, feature, theme, canvasMatrix, simplifier);
    } else {
      throw VectorMapError(
          'Unrecognized geometry: ' + geometry.runtimeType.toString());
    }
  }

  static PaintableFeature _point(
      MapPoint point,
      MapFeature feature,
      MapTheme theme,
      CanvasMatrix canvasMatrix,
      GeometrySimplifier simplifier) {
    return theme.markerBuilder.build(
        feature: feature,
        offset: Offset(point.x, point.y),
        scale: canvasMatrix.scale);
  }

  static PaintableFeature _linearRing(
      MapLinearRing linearRing,
      MapFeature feature,
      MapTheme theme,
      CanvasMatrix canvasMatrix,
      GeometrySimplifier simplifier) {
    SimplifiedPath simplifiedPath =
        linearRing.toSimplifiedPath(canvasMatrix, simplifier);
    return PaintablePath(simplifiedPath.path, simplifiedPath.pointsCount);
  }

  static PaintableFeature _polygon(
      MapPolygon polygon,
      MapFeature feature,
      MapTheme theme,
      CanvasMatrix canvasMatrix,
      GeometrySimplifier simplifier) {
    SimplifiedPath simplifiedPath =
        polygon.toSimplifiedPath(canvasMatrix, simplifier);
    return PaintablePath(simplifiedPath.path, simplifiedPath.pointsCount);
  }

  static PaintableFeature _multiPolygon(
      MapMultiPolygon multiPolygon,
      MapFeature feature,
      MapTheme theme,
      CanvasMatrix canvasMatrix,
      GeometrySimplifier simplifier) {
    Path path = Path();
    int pointsCount = 0;
    for (MapPolygon polygon in multiPolygon.polygons) {
      SimplifiedPath simplifiedPath =
          polygon.toSimplifiedPath(canvasMatrix, simplifier);
      pointsCount += simplifiedPath.pointsCount;
      path.addPath(simplifiedPath.path, Offset.zero);
    }
    return PaintablePath(path, pointsCount);
  }
}

/// Defines how a [MapFeature] should be painted on the map.
abstract class PaintableFeature {
  /// Gets the geometry bounds
  Rect getBounds();

  /// Draws this paintable on the canvas.
  drawOn(Canvas canvas, Paint paint, double scale);

  /// Gets the count of points for this paintable.
  int get pointsCount;

  /// Checks whether a point is contained in this paintable.
  bool contains(Offset offset);
}

/// Defines a path to be painted on the map.
class PaintablePath extends PaintableFeature {
  PaintablePath(Path path, int pointsCount)
      : this._path = path,
        this._pointsCount = pointsCount;

  final Path _path;
  final int _pointsCount;

  @override
  drawOn(Canvas canvas, Paint paint, double scale) {
    canvas.drawPath(_path, paint);
  }

  @override
  Rect getBounds() {
    return _path.getBounds();
  }

  @override
  bool contains(Offset offset) {
    return _path.contains(offset);
  }

  @override
  int get pointsCount => _pointsCount;
}

/// [Marker] builder.
abstract class MarkerBuilder {
  const MarkerBuilder();

  /// Builds a [Marker]
  Marker build(
      {required MapFeature feature,
      required Offset offset,
      required double scale});
}

/// Defines a marker to be painted on the map.
abstract class Marker extends PaintableFeature {
  Marker({required this.offset});

  final Offset offset;

  @override
  drawOn(Canvas canvas, Paint paint, double scale) {
    drawMarkerOn(canvas, paint, offset, scale);
  }

  @override
  int get pointsCount => 1;

  /// Draw this marker on [Canvas]
  drawMarkerOn(Canvas canvas, Paint paint, Offset offset, double scale);
}

/// Defines a circle marker to be painted on the map.
class CircleMaker extends Marker {
  CircleMaker(
      {required Offset offset,
      required double radius,
      required double scaledRadius})
      : this._bounds = Rect.fromLTWH(offset.dx - scaledRadius,
            offset.dy - scaledRadius, scaledRadius * 2, scaledRadius * 2),
        this._radius = radius,
        super(offset: offset);

  final Rect _bounds;
  final double _radius;

  @override
  bool contains(Offset offset) {
    return _bounds.contains(offset);
  }

  @override
  drawMarkerOn(Canvas canvas, Paint paint, Offset offset, double scale) {
    canvas.drawCircle(offset, _radius / scale, paint);
  }

  @override
  Rect getBounds() {
    return _bounds;
  }
}

/// [CircleMaker] builder.
/// The default [radius] value is [5].
class CircleMakerBuilder extends MarkerBuilder {
  const CircleMakerBuilder({double radius = 5, this.key, this.radiuses})
      : this.radius = radius;

  final double radius;
  final String? key;
  final Map<dynamic, double>? radiuses;

  @override
  Marker build(
      {required MapFeature feature,
      required Offset offset,
      required double scale}) {
    double r = radius;
    if (key != null && radiuses != null) {
      dynamic value = feature.getValue(key!);
      if (value != null && radiuses!.containsKey(value)) {
        r = radiuses![value]!;
      }
    }
    return CircleMaker(offset: offset, radius: r, scaledRadius: r / scale);
  }
}
