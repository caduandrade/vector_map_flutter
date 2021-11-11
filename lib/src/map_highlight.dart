import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';

/// Base class to define which [MapFeature] should be highlighted.
abstract class MapHighlight {
  MapHighlight({required this.layerId});

  /// Identifier of the layer to be highlighted.
  final int layerId;

  /// Identifies whether the rule applies to a given [MapFeature].
  bool applies(MapFeature feature);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapHighlight &&
          runtimeType == other.runtimeType &&
          layerId == other.layerId;

  @override
  int get hashCode => layerId.hashCode;
}

/// Defines a single [MapFeature] to be highlighted.
class MapSingleHighlight extends MapHighlight {
  MapSingleHighlight({required int layerId, this.drawableFeature})
      : super(layerId: layerId);

  final DrawableFeature? drawableFeature;

  @override
  bool applies(MapFeature feature) {
    return this.drawableFeature?.feature == feature;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is MapSingleHighlight &&
          runtimeType == other.runtimeType &&
          drawableFeature == other.drawableFeature;

  @override
  int get hashCode => super.hashCode ^ drawableFeature.hashCode;
}

/// Rule to find out which [MapFeature] should be highlighted.
class MapGradientHighlight extends MapHighlight {
  /// Builds a [MapHighlight]
  ///
  /// The [rangePerPixel] is the range of value represented by each legend
  /// bar pixel, that is, the range between the min and the max values
  /// divided by the height of the legend bar.
  factory MapGradientHighlight(
      {required int layerId,
      required String key,
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
    return MapGradientHighlight._(
        layerId: layerId,
        key: key,
        value: value,
        rangePerPixel: rangePerPixel,
        comparator: comparator);
  }

  /// Builds a [MapGradientHighlight]
  MapGradientHighlight._(
      {required int layerId,
      required this.key,
      required this.value,
      required this.rangePerPixel,
      required this.comparator})
      : super(layerId: layerId);

  final String key;
  final double value;
  final double rangePerPixel;
  final int comparator;

  static const int precisionPixels = 3;
  static const int comparatorPrecisionPixels = 2 * precisionPixels;

  /// Identifies whether the rule applies to a given [MapFeature].
  @override
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

  /// Indicates whether to compare with larger values.
  bool greater() {
    return comparator == 1;
  }

  /// Indicates whether to compare with smaller values.
  bool smaller() {
    return comparator == -1;
  }

  String get formattedValue {
    if (greater()) {
      return '> ' + value.roundToDouble().toString();
    } else if (smaller()) {
      return '< ' + value.roundToDouble().toString();
    }
    return '≈ ' + value.roundToDouble().toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is MapGradientHighlight &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value &&
          rangePerPixel == other.rangePerPixel &&
          comparator == other.comparator;

  @override
  int get hashCode =>
      super.hashCode ^
      key.hashCode ^
      value.hashCode ^
      rangePerPixel.hashCode ^
      comparator.hashCode;
}
