import 'package:vector_map/src/data/map_feature.dart';

/// Rule to find out which [MapFeature] should be highlighted.
class HighlightRule {
  /// Builds a [HighlightRule]
  ///
  /// The [rangePerPixel] is the range of value represented by each legend
  /// bar pixel, that is, the range between the min and the max values
  /// divided by the height of the legend bar.
  factory HighlightRule(
      {required String key,
      required double value,
      required double rangePerPixel,
      required double max,
      required double min}) {
    int comparator = 0;
    double r = comparatorPrecisionPixels * rangePerPixel;
    if (value > max - r) {
      comparator = 1;
    } else if (value < min + r) {
      comparator = -1;
    }
    return HighlightRule._(
        key: key,
        value: value,
        rangePerPixel: rangePerPixel,
        comparator: comparator);
  }

  HighlightRule._(
      {required this.key,
      required this.value,
      required this.rangePerPixel,
      required this.comparator});

  final String key;
  final double value;
  final double rangePerPixel;
  final int comparator;

  static const int precisionPixels = 3;
  static const int comparatorPrecisionPixels = 2 * precisionPixels;

  /// Identifies whether the rule applies to a given [MapFeature].
  bool applies(MapFeature feature) {
    double? featureValue = feature.getDoubleValue(key);
    if (featureValue != null) {
      if (greater()) {
        return value < featureValue;
      } else if (smaller()) {
        return value > featureValue;
      } else {
        double r = rangePerPixel * precisionPixels;
        if (value - r <= featureValue && featureValue <= value + r) {
          return true;
        }
      }
    }
    return false;
  }

  bool greater() {
    return comparator == 1;
  }

  bool smaller() {
    return comparator == -1;
  }

  @override
  String toString() {
    if (greater()) {
      return '> ' + value.roundToDouble().toString();
    } else if (smaller()) {
      return '< ' + value.roundToDouble().toString();
    }
    return '≈ ' + value.roundToDouble().toString();
  }
}
