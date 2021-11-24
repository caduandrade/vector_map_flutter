import 'package:flutter/rendering.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/drawable/drawable.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/drawable/drawable_layer_chunk.dart';
import 'package:vector_map/src/map_highlight.dart';
import 'package:vector_map/src/theme/map_theme.dart';

/// Draw utils for [VectorMap].
class DrawUtils {
  /// Draws the features on a given canvas.
  ///
  /// Only features that match [highlightRule] will be drawn.
  static void draw(
      {required Canvas canvas,
      required DrawableLayerChunk chunk,
      required MapLayer layer,
      required double contourThickness,
      required double scale,
      required bool antiAlias,
      MapHighlight? highlightRule}) {
    MapDataSource dataSource = layer.dataSource;
    MapTheme theme = layer.theme;
    Color? highlightColor = layer.highlightTheme?.color;

    for (int index = 0; index < chunk.length; index++) {
      DrawableFeature drawableFeature = chunk.getDrawableFeature(index);
      MapFeature feature = drawableFeature.feature;
      Drawable? drawable = drawableFeature.drawable;
      if (drawable != null && drawable.visible && drawable.hasFill) {
        Color color;
        if (highlightColor != null &&
            highlightRule != null &&
            highlightRule.applies(feature)) {
          color = highlightColor;
        } else {
          color = MapTheme.getThemeOrDefaultColor(dataSource, feature, theme);
        }
        var paint = Paint()
          ..style = PaintingStyle.fill
          ..color = color
          ..isAntiAlias = antiAlias;
        drawable.drawOn(canvas, paint, scale);
      }
    }

    if (contourThickness > 0) {
      DrawUtils.drawContour(
          canvas: canvas,
          layer: layer,
          chunk: chunk,
          contourThickness: contourThickness,
          scale: scale,
          antiAlias: antiAlias,
          highlightRule: highlightRule);
    }
  }

  /// Draws the contour of the features on a given canvas.
  ///
  /// Only features that match [highlightRule] will be drawn.
  static void drawContour(
      {required Canvas canvas,
      required DrawableLayerChunk chunk,
      required MapLayer layer,
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

    for (int index = 0; index < chunk.length; index++) {
      DrawableFeature drawableFeature = chunk.getDrawableFeature(index);
      Drawable? drawable = drawableFeature.drawable;
      if (drawable != null && drawable.visible) {
        if (highlightRule != null) {
          MapFeature feature = drawableFeature.feature;
          if (highlightRule.applies(feature) == false) {
            continue;
          }
        }
        drawable.drawOn(canvas, paint, scale);
      }
    }
  }

  /// Draws the features that match [MapMultiHighlight] on a given canvas.
  static void drawHighlight(
      {required Canvas canvas,
      required DrawableLayer drawableLayer,
      required Paint paint,
      required double scale,
      required bool fillOnly,
      required MapHighlight highlight}) {
    for (DrawableLayerChunk chunk in drawableLayer.chunks) {
      for (int index = 0; index < chunk.length; index++) {
        DrawableFeature drawableFeature = chunk.getDrawableFeature(index);
        MapFeature feature = drawableFeature.feature;
        Drawable? drawable = drawableFeature.drawable;
        if (drawable != null && drawable.visible) {
          if (fillOnly && drawable.hasFill == false) {
            continue;
          }
          if (highlight.applies(feature)) {
            drawable.drawOn(canvas, paint, scale);
          }
        }
      }
    }
  }
}
