import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/map_highlight.dart';
import 'package:vector_map/src/theme/map_theme.dart';

/// Holds all geometry layers to be paint in the current resolution.
class DrawableLayer {
  DrawableLayer(this.layer, this.drawableFeatures);

  final MapLayer layer;
  final Map<int, DrawableFeature> drawableFeatures;

  /// Gets a [DrawableFeature] for a given [MapFeature].
  DrawableFeature getDrawableFeature(MapFeature feature) {
    int featureId = feature.id;
    if (drawableFeatures.containsKey(featureId) == false) {
      throw VectorMapError('No DrawableFeature for feature id: $featureId');
    }
    return drawableFeatures[featureId]!;
  }

  /// Draws the features on a given canvas.
  ///
  /// Only features that match [highlightRule] will be drawn.
  void drawOn(
      {required Canvas canvas,
      required double contourThickness,
      required double scale,
      required bool antiAlias,
      MapHighlight? highlightRule}) {
    MapDataSource dataSource = layer.dataSource;
    MapTheme theme = layer.theme;
    Color? highlightColor = layer.highlightTheme?.color;

    Map<int, Color> colors = Map<int, Color>();
    for (int id in drawableFeatures.keys) {
      MapFeature feature = dataSource.features[id]!;
      if (highlightRule != null) {
        if (highlightColor != null && highlightRule.applies(feature)) {
          colors[feature.id] = highlightColor;
        }
      } else {
        colors[feature.id] =
            MapTheme.getThemeOrDefaultColor(dataSource, feature, theme);
      }
    }

    for (int featureId in colors.keys) {
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
          antiAlias: antiAlias,
          highlightRule: highlightRule);
    }
  }

  /// Draws the contour of the features on a given canvas.
  ///
  /// Only features that match [highlightRule] will be drawn.
  void drawContourOn(
      {required Canvas canvas,
      required double contourThickness,
      required double scale,
      required bool antiAlias,
      MapHighlight? highlightRule}) {
    MapTheme theme = layer.theme;

    late Color contourColor;
    if (highlightRule != null && layer.highlightTheme?.contourColor != null) {
      contourColor = layer.highlightTheme!.contourColor!;
    } else {
      contourColor = theme.contourColor != null
          ? theme.contourColor!
          : MapTheme.defaultContourColor;
    }

    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = contourColor
      ..strokeWidth = contourThickness / scale
      ..isAntiAlias = antiAlias;

    for (int id in drawableFeatures.keys) {
      DrawableFeature drawableFeature = drawableFeatures[id]!;
      if (drawableFeature.visible) {
        if (highlightRule != null) {
          MapFeature feature = layer.dataSource.features[id]!;
          if (highlightRule.applies(feature) == false) {
            continue;
          }
        }
        drawableFeature.drawOn(canvas, paint, scale);
      }
    }
  }

  /// Draws the features that match [MapMultiHighlight] on a given canvas.
  void drawHighlightOn(
      {required Canvas canvas,
      required Paint paint,
      required double scale,
      required bool fillOnly,
      required MapHighlight highlight}) {
    MapDataSource dataSource = layer.dataSource;
    for (int id in drawableFeatures.keys) {
      MapFeature feature = dataSource.features[id]!;
      DrawableFeature drawableFeature = getDrawableFeature(feature);
      if (drawableFeature.visible) {
        if (fillOnly && drawableFeature.hasFill == false) {
          continue;
        }
        if (highlight.applies(feature)) {
          drawableFeature.drawOn(canvas, paint, scale);
        }
      }
    }
  }
}
