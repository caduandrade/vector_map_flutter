import 'package:flutter/rendering.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/property_limits.dart';
import 'package:vector_map/src/drawable/marker.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/theme/map_theme.dart';

/// Theme for gradient colors.
///
/// The gradient is created given the colors and limit values of the
/// chosen property.
/// The property must have numeric values.
/// If the [min] is set, all smaller values will be displayed with the first
/// gradient color.
/// If the [max] is set, all larger values will be displayed with the last
/// gradient color.
class MapGradientTheme extends MapTheme {
  MapGradientTheme(
      {Color? color,
      Color? contourColor,
      LabelVisibility? labelVisibility,
      LabelStyleBuilder? labelStyleBuilder,
      MarkerBuilder? markerBuilder,
      double? min,
      double? max,
      required this.key,
      required this.colors})
      : this._max = max,
        this._min = min,
        super(
            color: color,
            contourColor: contourColor,
            labelVisibility: labelVisibility,
            labelStyleBuilder: labelStyleBuilder,
            markerBuilder: markerBuilder) {
    if (colors.length < 2) {
      throw VectorMapError('At least 2 colors are required for the gradient.');
    }
  }

  final double? _min;
  final double? _max;
  final String key;
  final List<Color> colors;

  @override
  bool hasValue() {
    //It is not possible to know in advance, it depends on the property values.
    return true;
  }

  double? min(MapDataSource dataSource) {
    double? min = this._min;
    if (min == null) {
      PropertyLimits? propertyLimits = dataSource.getPropertyLimits(key);
      if (propertyLimits != null) {
        min = propertyLimits.min;
      }
    }
    return min;
  }

  double? max(MapDataSource dataSource) {
    double? max = this._max;
    if (max == null) {
      PropertyLimits? propertyLimits = dataSource.getPropertyLimits(key);
      if (propertyLimits != null) {
        max = propertyLimits.max;
      }
    }
    return max;
  }

  @override
  Color? getColor(MapDataSource dataSource, MapFeature feature) {
    double? min = this.min(dataSource);
    double? max = this.max(dataSource);

    if (min != null && max != null) {
      dynamic dynamicValue = feature.getValue(key);
      double? value;
      if (dynamicValue is int) {
        value = dynamicValue.toDouble();
      } else if (dynamicValue is double) {
        value = dynamicValue;
      }
      if (value != null) {
        if (value <= min) {
          return colors.first;
        }
        if (value >= max) {
          return colors.last;
        }

        double size = max - min;

        int stepsCount = colors.length - 1;
        double stepSize = size / stepsCount;
        int stepIndex = (value - min) ~/ stepSize;

        double currentStepRange = (stepIndex * stepSize) + stepSize;
        double positionInStep = value - min - (stepIndex * stepSize);
        double t = positionInStep / currentStepRange;
        return Color.lerp(colors[stepIndex], colors[stepIndex + 1], t)!;
      }
    }
    return super.getColor(dataSource, feature);
  }
}
