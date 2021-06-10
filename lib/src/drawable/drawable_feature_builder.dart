import 'dart:ui';

import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_line.dart';
import 'package:vector_map/src/drawable/drawable_polygon.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/matrix.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme.dart';

/// [DrawableFeature] builder.
class DrawableFeatureBuilder {
  static DrawableFeature build(
      MapDataSource dataSource,
      MapFeature feature,
      MapTheme theme,
      CanvasMatrix canvasMatrix,
      GeometrySimplifier simplifier) {
    MapGeometry geometry = feature.geometry;
    if (geometry is MapPoint) {
      return _point(
          dataSource, feature, geometry, theme, canvasMatrix, simplifier);
    } else if (geometry is MapLinearRing) {
      return _linearRing(feature, geometry, theme, canvasMatrix, simplifier);
    } else if (geometry is MapLineString) {
      return _lineString(feature, geometry, theme, canvasMatrix, simplifier);
    } else if (geometry is MapPolygon) {
      return _polygon(feature, geometry, theme, canvasMatrix, simplifier);
    } else if (geometry is MapMultiPolygon) {
      return _multiPolygon(feature, geometry, theme, canvasMatrix, simplifier);
    } else {
      throw VectorMapError(
          'Unrecognized geometry: ' + geometry.runtimeType.toString());
    }
  }

  static DrawableFeature _point(
      MapDataSource dataSource,
      MapFeature feature,
      MapPoint point,
      MapTheme theme,
      CanvasMatrix canvasMatrix,
      GeometrySimplifier simplifier) {
    return theme.markerBuilder.build(
        dataSource: dataSource,
        feature: feature,
        offset: Offset(point.x, point.y),
        scale: canvasMatrix.scale);
  }

  static DrawableFeature _lineString(
      MapFeature feature,
      MapLineString lineString,
      MapTheme theme,
      CanvasMatrix canvasMatrix,
      GeometrySimplifier simplifier) {
    SimplifiedPath simplifiedPath =
        lineString.toSimplifiedPath(canvasMatrix, simplifier);
    return DrawableLine(simplifiedPath.path, simplifiedPath.pointsCount);
  }

  static DrawableFeature _linearRing(
      MapFeature feature,
      MapLinearRing linearRing,
      MapTheme theme,
      CanvasMatrix canvasMatrix,
      GeometrySimplifier simplifier) {
    SimplifiedPath simplifiedPath =
        linearRing.toSimplifiedPath(canvasMatrix, simplifier);
    return DrawablePolygon(simplifiedPath.path, simplifiedPath.pointsCount);
  }

  static DrawableFeature _polygon(
      MapFeature feature,
      MapPolygon polygon,
      MapTheme theme,
      CanvasMatrix canvasMatrix,
      GeometrySimplifier simplifier) {
    SimplifiedPath simplifiedPath =
        polygon.toSimplifiedPath(canvasMatrix, simplifier);
    return DrawablePolygon(simplifiedPath.path, simplifiedPath.pointsCount);
  }

  static DrawableFeature _multiPolygon(
      MapFeature feature,
      MapMultiPolygon multiPolygon,
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
    return DrawablePolygon(path, pointsCount);
  }
}
