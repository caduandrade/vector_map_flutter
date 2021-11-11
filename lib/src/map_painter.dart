import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/draw_utils.dart';
import 'package:vector_map/src/drawable/drawable.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/drawable/drawable_layer_chunk.dart';
import 'package:vector_map/src/map_highlight.dart';
import 'package:vector_map/src/theme/map_highlight_theme.dart';
import 'package:vector_map/src/theme/map_theme.dart';
import 'package:vector_map/src/vector_map_controller.dart';

/// Painter for [VectorMap].
class MapPainter extends CustomPainter {
  MapPainter({required this.controller, required this.drawBuffers});
  final VectorMapController controller;
  final bool drawBuffers;

  @override
  void paint(Canvas canvas, Size size) {
    MapHighlight? highlight = controller.highlight;

    DrawableLayer? overlayContourDrawableLayer;

    // drawing layers
    for (int layerIndex = 0;
        layerIndex < controller.layersCount;
        layerIndex++) {
      DrawableLayer drawableLayer = controller.getDrawableLayer(layerIndex);
      for (DrawableLayerChunk chunk in drawableLayer.chunks) {
        if (drawBuffers && chunk.buffer != null) {
          canvas.drawImage(chunk.buffer!, Offset.zero, Paint());
        } else {
          // resizing, panning or zooming
          canvas.save();
          controller.applyMatrixOn(canvas);
          // drawing contour only to be faster
          DrawUtils.drawContour(
              canvas: canvas,
              chunk: chunk,
              layer: drawableLayer.layer,
              contourThickness: controller.contourThickness,
              scale: controller.scale,
              antiAlias: false);
          canvas.restore();
        }
      }

      MapLayer layer = drawableLayer.layer;

      // highlighting
      if (highlight != null &&
          highlight.layerId == layer.id &&
          layer.highlightTheme != null) {
        if (controller.contourThickness > 0 &&
            layer.highlightTheme!.overlayContour) {
          overlayContourDrawableLayer = drawableLayer;
        }

        canvas.save();
        controller.applyMatrixOn(canvas);

        if (layer.highlightTheme!.color != null) {
          var paint = Paint()
            ..style = PaintingStyle.fill
            ..color = layer.highlightTheme!.color!
            ..isAntiAlias = true;
          if (highlight is MapSingleHighlight) {
            DrawableFeature? drawableFeature = highlight.drawableFeature;
            Drawable? drawable = drawableFeature?.drawable;
            if (drawable != null && drawable.visible && drawable.hasFill) {
              drawable.drawOn(canvas, paint, controller.scale);
            }
          } else {
            DrawUtils.drawHighlight(
                canvas: canvas,
                drawableLayer: drawableLayer,
                paint: paint,
                scale: controller.scale,
                fillOnly: true,
                highlight: highlight);
          }
        }

        if (controller.contourThickness > 0 &&
            layer.highlightTheme!.overlayContour == false) {
          _drawHighlightContour(canvas, drawableLayer, controller);
        }

        canvas.restore();
      }
    }

    // drawing the overlay highlight contour
    if (overlayContourDrawableLayer != null) {
      canvas.save();
      controller.applyMatrixOn(canvas);
      _drawHighlightContour(canvas, overlayContourDrawableLayer, controller);
      canvas.restore();
    }

    // drawing labels
    for (int layerIndex = 0;
        layerIndex < controller.layersCount;
        layerIndex++) {
      DrawableLayer drawableLayer = controller.getDrawableLayer(layerIndex);
      MapLayer layer = drawableLayer.layer;
      MapDataSource dataSource = layer.dataSource;
      MapTheme theme = layer.theme;
      MapHighlightTheme? highlightTheme = layer.highlightTheme;
      if (theme.labelVisibility != null ||
          (highlightTheme != null && highlightTheme.labelVisibility != null)) {
        for (DrawableLayerChunk chunk in drawableLayer.chunks) {
          for (int index = 0; index < chunk.length; index++) {
            DrawableFeature drawableFeature = chunk.getDrawableFeature(index);
            MapFeature feature = drawableFeature.feature;
            Drawable? drawable = drawableFeature.drawable;
            if (drawable != null && drawable.visible && feature.label != null) {
              LabelVisibility? labelVisibility;
              if (highlight != null &&
                  highlight.layerId == layer.id &&
                  highlight.applies(feature) &&
                  highlightTheme != null &&
                  highlightTheme.labelVisibility != null) {
                labelVisibility = highlightTheme.labelVisibility;
              } else {
                labelVisibility = theme.labelVisibility;
              }
              if (labelVisibility != null && labelVisibility(feature)) {
                LabelStyleBuilder? labelStyleBuilder;
                MapHighlightTheme? highlightTheme;
                if (highlight != null && highlight.applies(feature)) {
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
                    canvas, feature, drawable, featureColor, labelStyleBuilder);
              }
            }
          }
        }
      }
    }
  }

  void _drawHighlightContour(Canvas canvas, DrawableLayer drawableLayer,
      VectorMapController controller) {
    MapHighlight? highlight = controller.highlight;
    Color? color = MapTheme.getContourColor(
        drawableLayer.layer.theme, drawableLayer.layer.highlightTheme);
    if (color != null) {
      var paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = controller.contourThickness / controller.scale
        ..isAntiAlias = true;
      if (highlight is MapSingleHighlight) {
        DrawableFeature? drawableFeature = highlight.drawableFeature;
        Drawable? drawable = drawableFeature?.drawable;
        if (drawable != null && drawable.visible) {
          drawable.drawOn(canvas, paint, controller.scale);
        }
      } else {
        DrawUtils.drawHighlight(
            canvas: canvas,
            drawableLayer: drawableLayer,
            paint: paint,
            scale: controller.scale,
            fillOnly: false,
            highlight: highlight!);
      }
    }
  }

  void _drawLabel(Canvas canvas, MapFeature feature, Drawable drawable,
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

    Rect bounds = MatrixUtils.transformRect(
        controller.worldToCanvas, drawable.getBounds());
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
    return true;
  }
}
