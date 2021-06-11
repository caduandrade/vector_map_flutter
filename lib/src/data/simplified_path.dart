import 'dart:ui';

/// Stores a simplified path generated from the original [MapFeature] geometry.
class SimplifiedPath {
  SimplifiedPath(this.path, this.pointsCount);

  final Path path;
  final int pointsCount;
}
