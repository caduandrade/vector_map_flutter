import 'dart:ui';

import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/theme/theme.dart';
import 'package:vector_map/src/typedefs.dart';

/// Holds all geometry layers to be paint in the current resolution.
class DrawableLayer {
  DrawableLayer(this.layer, this.drawableFeatures);

  final MapLayer layer;
  final Map<int, DrawableFeature> drawableFeatures;

  /// Finds the first feature that contains a coordinate.
  MapFeature? featureContains(HoverRule? hoverRule, Offset worldCoordinate) {
    for (MapFeature feature in layer.dataSource.features.values) {
      if (hoverRule != null && hoverRule(feature) == false) {
        continue;
      }

      if (drawableFeatures.containsKey(feature.id) == false) {
        throw VectorMapError(
            'No drawable geometry for id: ' + feature.id.toString());
      }
      DrawableFeature drawableFeature = drawableFeatures[feature.id]!;
      if (drawableFeature.contains(worldCoordinate)) {
        return feature;
      }
    }
  }

  drawOn(
      {required Canvas canvas,
      required double contourThickness,
      required double scale,
      required bool antiAlias}) {
    MapDataSource dataSource = layer.dataSource;
    MapTheme theme = layer.theme;

    Map<int, Color> colors = Map<int, Color>();
    for (int id in drawableFeatures.keys) {
      MapFeature feature = dataSource.features[id]!;
      colors[feature.id] =
          MapTheme.getThemeOrDefaultColor(dataSource, feature, theme);
    }

    for (int featureId in drawableFeatures.keys) {
      DrawableFeature drawableFeature = drawableFeatures[featureId]!;
      if (drawableFeature.visible && drawableFeature.hasFill) {
        Color color = colors[featureId]!;

        var paint = Paint()
          ..style = PaintingStyle.fill
          ..color = color
          ..isAntiAlias = antiAlias;
        drawableFeature.drawOn(canvas, paint, scale);
      }
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
    for (DrawableFeature drawableFeature in drawableFeatures.values) {
      if (drawableFeature.visible) {
        drawableFeature.drawOn(canvas, paint, scale);
      }
    }
  }
}
