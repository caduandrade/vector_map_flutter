import 'dart:ui' as ui;

import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';

class DrawableLayerChunk {
  final List<DrawableFeature> _drawableFeatures = [];
  ui.Image? buffer;

  int _pointsCount = 0;
  int get pointsCount => _pointsCount;

  int get length => _drawableFeatures.length;

  DrawableFeature getDrawableFeature(int index) {
    return _drawableFeatures[index];
  }

  void add(MapFeature feature) {
    _drawableFeatures.add(DrawableFeature(feature));
    _pointsCount += feature.geometry.pointsCount;
  }
}
