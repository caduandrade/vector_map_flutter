import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/map_highlight.dart';
import 'package:vector_map/src/map_resolution.dart';
import 'package:vector_map/src/matrix.dart';
import 'package:vector_map/src/theme/map_highlight_theme.dart';
import 'package:vector_map/src/theme/map_theme.dart';

/// Painter for [VectorMap].
class MapPainter extends CustomPainter {
  MapPainter(
      {required this.mapResolution,
      required this.canvasMatrix,
      required this.contourThickness,
      this.highlight});

  final CanvasMatrix canvasMatrix;
  final MapHighlight? highlight;
  final double contourThickness;
  final MapResolution mapResolution;

  @override
  void paint(Canvas canvas, Size size) {
    // drawing layers
    for (int layerIndex = 0;
        layerIndex < mapResolution.drawableLayers.length;
        layerIndex++) {
      DrawableLayer drawableLayer = mapResolution.drawableLayers[layerIndex];

      if (canvasMatrix.widgetSize == mapResolution.widgetSize) {
        canvas.drawImage(
            mapResolution.layerBuffers[layerIndex], Offset.zero, Paint());
      } else {
        // resizing, panning or zooming
        canvas.save();
        canvasMatrix.applyOn(canvas);
        // drawing contour only to be faster
        drawableLayer.drawContourOn(
            canvas: canvas,
            contourThickness: contourThickness,
            scale: canvasMatrix.scale,
            antiAlias: false);
        canvas.restore();
      }

      // highlighting
      if (highlight != null && highlight!.layerIndex == layerIndex) {
        MapLayer layer = drawableLayer.layer;
        if (layer.highlightTheme != null) {
          canvas.save();
          canvasMatrix.applyOn(canvas);

          if (layer.highlightTheme!.color != null) {
            var paint = Paint()
              ..style = PaintingStyle.fill
              ..color = layer.highlightTheme!.color!
              ..isAntiAlias = true;
            if (highlight is MapSingleHighlight) {
              MapFeature feature = (highlight as MapSingleHighlight).feature;
              DrawableFeature drawableFeature =
                  drawableLayer.getDrawableFeature(feature);
              if (drawableFeature.visible && drawableFeature.hasFill) {
                drawableFeature.drawOn(canvas, paint, canvasMatrix.scale);
              }
            } else {
              drawableLayer.drawHighlightOn(
                  canvas: canvas,
                  paint: paint,
                  scale: canvasMatrix.scale,
                  fillOnly: true,
                  highlight: highlight!);
            }
          }

          if (contourThickness > 0 &&
              layer.highlightTheme!.overlayContour == false) {
            _drawHighlightContour(canvas, drawableLayer, canvasMatrix);
          }

          canvas.restore();
        }
      }
    }

    // drawing the overlay highlight contour
    if (contourThickness > 0 && highlight != null) {
      DrawableLayer drawableLayer =
          mapResolution.drawableLayers[highlight!.layerIndex];
      if (drawableLayer.layer.highlightTheme != null) {
        MapHighlightTheme highlightTheme = drawableLayer.layer.highlightTheme!;
        if (highlightTheme.overlayContour) {
          canvas.save();
          canvasMatrix.applyOn(canvas);
          _drawHighlightContour(canvas, drawableLayer, canvasMatrix);
          canvas.restore();
        }
      }
    }

    // drawing labels
    for (int layerIndex = 0;
        layerIndex < mapResolution.drawableLayers.length;
        layerIndex++) {
      DrawableLayer drawableLayer = mapResolution.drawableLayers[layerIndex];
      MapLayer layer = drawableLayer.layer;
      MapDataSource dataSource = layer.dataSource;
      MapTheme theme = layer.theme;
      MapHighlightTheme? highlightTheme = layer.highlightTheme;
      if (theme.labelVisibility != null ||
          (highlightTheme != null && highlightTheme.labelVisibility != null)) {
        for (MapFeature feature in dataSource.features.values) {
          DrawableFeature drawableFeature =
              drawableLayer.drawableFeatures[feature.id]!;
          if (drawableFeature.visible && feature.label != null) {
            LabelVisibility? labelVisibility;
            if (highlight != null &&
                highlight!.layerIndex == layerIndex &&
                highlight!.applies(feature) &&
                highlightTheme != null &&
                highlightTheme.labelVisibility != null) {
              labelVisibility = highlightTheme.labelVisibility;
            } else {
              labelVisibility = theme.labelVisibility;
            }
            if (labelVisibility != null && labelVisibility(feature)) {
              LabelStyleBuilder? labelStyleBuilder;
              MapHighlightTheme? highlightTheme;
              if (highlight != null && highlight!.applies(feature)) {
                highlightTheme = layer.highlightTheme;
                if (highlightTheme != null) {
                  labelStyleBuilder = highlightTheme.labelStyleBuilder;
                }
              }
              Color featureColor = MapTheme.getFeatureColor(
                  dataSource, feature, theme, highlightTheme);
              if (labelStyleBuilder == null) {
                labelStyleBuilder = theme.labelStyleBuilder;
              }
              _drawLabel(
                  canvas, layerIndex, feature, featureColor, labelStyleBuilder);
            }
          }
        }
      }
    }
  }

  _drawHighlightContour(
      Canvas canvas, DrawableLayer drawableLayer, CanvasMatrix canvasMatrix) {
    Color? color = MapTheme.getContourColor(
        drawableLayer.layer.theme, drawableLayer.layer.highlightTheme);
    if (color != null) {
      var paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = contourThickness / canvasMatrix.scale
        ..isAntiAlias = true;
      if (highlight is MapSingleHighlight) {
        MapFeature feature = (highlight as MapSingleHighlight).feature;
        DrawableFeature drawableFeature =
            drawableLayer.getDrawableFeature(feature);
        if (drawableFeature.visible) {
          drawableFeature.drawOn(canvas, paint, canvasMatrix.scale);
        }
      } else {
        drawableLayer.drawHighlightOn(
            canvas: canvas,
            paint: paint,
            scale: canvasMatrix.scale,
            fillOnly: false,
            highlight: highlight!);
      }
    }
  }

  _drawLabel(Canvas canvas, int layerIndex, MapFeature feature,
      Color featureColor, LabelStyleBuilder? labelStyleBuilder) {
    Color labelColor = _labelColorFrom(featureColor);

    TextStyle? labelStyle;
    if (labelStyleBuilder != null) {
      labelStyle = labelStyleBuilder(feature, featureColor, labelColor);
    }
    if (labelStyle == null) {
      labelStyle = TextStyle(
        color: labelColor,
        fontSize: 11,
      );
    }

    DrawableLayer drawableLayer = mapResolution.drawableLayers[layerIndex];
    DrawableFeature drawableFeature =
        drawableLayer.drawableFeatures[feature.id]!;
    Rect bounds = MatrixUtils.transformRect(
        canvasMatrix.worldToScreen, drawableFeature.getBounds());
    _drawText(canvas, bounds.center, feature.label!, labelStyle);
  }

  Color _labelColorFrom(Color featureColor) {
    final luminance = featureColor.computeLuminance();
    if (luminance > 0.55) {
      return const Color(0xFF000000);
    }
    return const Color(0xFFFFFFFF);
  }

  void _drawText(
      Canvas canvas, Offset center, String text, TextStyle textStyle) {
    TextSpan textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: 0,
    );

    double xCenter = center.dx - (textPainter.width / 2);
    double yCenter = center.dy - (textPainter.height / 2);
    textPainter.paint(canvas, Offset(xCenter, yCenter));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
