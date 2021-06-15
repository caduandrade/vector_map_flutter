import 'package:vector_map/src/data/map_feature.dart';

/// Rule to find out which [MapFeature] should be highlighted.
class HighlightRule {
  HighlightRule(
      {required this.key, required this.value, required this.precision});

  final String key;
  final double value;
  final double precision;

  /// Identifies whether the rule applies to a given [MapFeature].
  bool applies(MapFeature feature) {
    double? featureValue = feature.getDoubleValue(key);
    if (featureValue != null) {
      if (value - (precision * 3) <= featureValue &&
          featureValue <= value + (precision * 3)) {
        return true;
      }
    }
    return false;
  }
}
