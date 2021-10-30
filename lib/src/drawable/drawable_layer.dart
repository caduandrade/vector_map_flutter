import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/drawable/drawable_layer_chunk.dart';

/// Holds all geometry layers to be paint in the current resolution.
class DrawableLayer {
  static const int pointsPerChunk = 35000;

  DrawableLayer._(this.layer, this.chunks);

  factory DrawableLayer(MapLayer layer) {
    List<DrawableLayerChunk> chunks = [];
    DrawableLayerChunk chunk = DrawableLayerChunk();
    for (MapFeature feature in layer.dataSource.features.values) {
      chunk.add(feature);
      if (chunk.pointsCount > pointsPerChunk) {
        chunks.add(chunk);
        chunk = DrawableLayerChunk();
      }
    }
    if (chunk.pointsCount > 0) {
      chunks.add(chunk);
    }
    return DrawableLayer._(layer, chunks);
  }

  final MapLayer layer;
  final List<DrawableLayerChunk> chunks;
}
