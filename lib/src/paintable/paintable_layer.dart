import 'dart:ui';

import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/layer.dart';
import 'package:vector_map/src/paintable/paintable_feature.dart';
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
      if (paintableFeature.visible && paintableFeature.hasFill) {
        Color color = colors[featureId]!;

        var paint = Paint()
          ..style = PaintingStyle.fill
          ..color = color
          ..isAntiAlias = antiAlias;
        paintableFeature.drawOn(canvas, paint, scale);
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
    for (PaintableFeature paintableFeature in paintableFeatures.values) {
      if (paintableFeature.visible) {
        paintableFeature.drawOn(canvas, paint, scale);
      }
    }
  }
}
