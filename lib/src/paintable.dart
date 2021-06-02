
import 'dart:ui';

import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/layer.dart';
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
      paintableFeature.drawOn(canvas, paint);
    }

    if (contourThickness > 0) {
      drawContourOn(canvas: canvas, contourThickness: contourThickness, scale: scale, antiAlias: antiAlias);
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
      paintableFeature.drawOn(canvas, paint);
    }
  }
}

/// Defines how a [MapFeature] should be painted on the map.
abstract class PaintableFeature {
  /// Gets the geometry bounds
  Rect getBounds();

  /// Draws this paintable on the canvas.
  drawOn(Canvas canvas, Paint paint);

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
  drawOn(Canvas canvas, Paint paint) {
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

  Marker build({required Offset offset, required double scale});
}

/// Defines a marker to be painted on the map.
abstract class Marker extends PaintableFeature {
  Marker({required this.offset});

  final Offset offset;

  @override
  drawOn(Canvas canvas, Paint paint) {
    drawMarkerOn(canvas, paint, offset);
  }

  @override
  int get pointsCount => 1;

  drawMarkerOn(Canvas canvas, Paint paint, Offset offset);
}

/// Defines a circle marker to be painted on the map.
class CircleMaker extends Marker {
  CircleMaker({required Offset offset, required double radius})
      : this._bounds = Rect.fromLTWH(
            offset.dx - radius, offset.dy - radius, radius * 2, radius * 2),
        this._radius = radius,
        super(offset: offset);

  final Rect _bounds;
  final double _radius;

  @override
  bool contains(Offset offset) {
    return _bounds.contains(offset);
  }

  @override
  drawMarkerOn(Canvas canvas, Paint paint, Offset offset) {
    canvas.drawCircle(offset, _radius, paint);
  }

  @override
  Rect getBounds() {
    return _bounds;
  }
}

/// [CircleMaker] builder.
class CircleMakerBuilder extends MarkerBuilder {
  const CircleMakerBuilder({required this.radius});

  final double radius;

  Marker build({required Offset offset, required double scale}) {
    return CircleMaker(offset: offset, radius: radius / scale);
  }
}
