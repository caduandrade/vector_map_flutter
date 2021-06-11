import 'dart:ui';

import 'package:vector_map/src/data/data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';

/// [Marker] builder.
abstract class MarkerBuilder {
  MarkerBuilder();

  /// Builds a [Marker]
  Marker build(
      {required MapDataSource dataSource,
      required MapFeature feature,
      required Offset offset,
      required double scale});
}

/// Defines a marker to be painted on the map.
abstract class Marker extends DrawableFeature {
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
