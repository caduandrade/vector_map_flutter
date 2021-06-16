import 'package:vector_map/src/data/map_feature.dart';

/// Rule to find out which [MapFeature] should be highlighted.
class HighlightRule {
  /// Builds a [HighlightRule]
  ///
  /// The [rangePerPixel] is the range of value represented by each legend
  /// bar pixel, that is, the range between the min and the max values
  /// divided by the height of the legend bar.
  HighlightRule(
      {required this.key, required this.value, required this.rangePerPixel});

  final String key;
  final double value;
  final double rangePerPixel;
  final int precisionPixels = 3;

  /// Identifies whether the rule applies to a given [MapFeature].
  bool applies(MapFeature feature) {
    double? featureValue = feature.getDoubleValue(key);
    if (featureValue != null) {
      if (value - (rangePerPixel * precisionPixels) <= featureValue &&
          featureValue <= value + (rangePerPixel * precisionPixels)) {
        return true;
      }
    }
    return false;
  }
}
