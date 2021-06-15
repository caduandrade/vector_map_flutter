import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/highlight_rule.dart';
import 'package:vector_map/src/theme/map_theme.dart';

/// Holds all geometry layers to be paint in the current resolution.
class DrawableLayer {
  DrawableLayer(this.layer, this.drawableFeatures);

  final MapLayer layer;
  final Map<int, DrawableFeature> drawableFeatures;

  drawOn(
      {required Canvas canvas,
      required double contourThickness,
      required double scale,
      required bool antiAlias,
      HighlightRule? highlightRule}) {
    MapDataSource dataSource = layer.dataSource;
    MapTheme theme = layer.theme;

    Map<int, Color> colors = Map<int, Color>();
    for (int id in drawableFeatures.keys) {
      MapFeature feature = dataSource.features[id]!;

      Color color = MapTheme.getThemeOrDefaultColor(dataSource, feature, theme);
      if (highlightRule != null && highlightRule.applies(feature)) {
        color = Colors.black;
      }

      colors[feature.id] = color;
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
