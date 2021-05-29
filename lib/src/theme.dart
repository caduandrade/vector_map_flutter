import 'package:flutter/material.dart';
import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/error.dart';

typedef LabelVisibility = bool Function(MapFeature feature);

/// Rule to obtain a color of a feature.
typedef ColorRule = Color? Function(MapFeature feature);

typedef LabelStyleBuilder = TextStyle Function(
    MapFeature feature, Color featureColor, Color labelColor);

class MapTheme {
  static const Color defaultColor = Color(0xFFE0E0E0);
  static const Color defaultContourColor = Color(0xFF9E9E9E);

  static Color getThemeOrDefaultColor(
      MapDataSource? dataSource, MapFeature feature, MapTheme theme) {
    Color? color = theme.getColor(dataSource, feature);
    if (color != null) {
      return color;
    }
    return MapTheme.defaultColor;
  }

  /// Creates a theme with colors by property value.
  static MapTheme value(
      {Color? color,
      Color? contourColor,
      LabelVisibility? labelVisibility,
      LabelStyleBuilder? labelStyleBuilder,
      required String key,
      Map<dynamic, Color>? colors}) {
    return _MapThemeValue(
        color: color,
        contourColor: contourColor,
        labelVisibility: labelVisibility,
        labelStyleBuilder: labelStyleBuilder,
        key: key,
        colors: colors);
  }

  /// Creates a theme with colors by rule.
  /// The feature color is obtained from the first rule that returns
  /// a non-null color.
  /// If all rules return a null color, the default color is used.
  static MapTheme rule(
      {Color? color,
      Color? contourColor,
      LabelVisibility? labelVisibility,
      LabelStyleBuilder? labelStyleBuilder,
      required List<ColorRule> colorRules}) {
    return _MapThemeRule(
        color: color,
        contourColor: contourColor,
        labelVisibility: labelVisibility,
        labelStyleBuilder: labelStyleBuilder,
        colorRules: colorRules);
  }

  /// Creates a theme with gradient colors.
  /// The gradient is created given the colors and limit values of the
  /// chosen property.
  /// The property must have numeric values.
  /// If the [min] is set, all smaller values will be displayed with the first
  /// gradient color.
  /// If the [max] is set, all larger values will be displayed with the last
  /// gradient color.
  static MapTheme gradient(
      {Color? color,
      Color? contourColor,
      LabelVisibility? labelVisibility,
      LabelStyleBuilder? labelStyleBuilder,
      double? min,
      double? max,
      required String key,
      required List<Color> colors}) {
    if (colors.length < 2) {
      throw VectorMapError('At least 2 colors are required for the gradient.');
    }

    return _MapThemeGradient(
        color: color,
        contourColor: contourColor,
        labelVisibility: labelVisibility,
        labelStyleBuilder: labelStyleBuilder,
        min: min,
        max: max,
        key: key,
        colors: colors);
  }

  /// Theme for [VectorMap]
  MapTheme(
      {Color? color,
      this.contourColor,
      this.labelVisibility,
      LabelStyleBuilder? labelStyleBuilder})
      : this._color = color,
        this.labelStyleBuilder = labelStyleBuilder;

  final Color? _color;
  final Color? contourColor;
  final LabelVisibility? labelVisibility;
  final LabelStyleBuilder? labelStyleBuilder;

  bool hasValue() {
    return _color != null || contourColor != null || labelVisibility != null;
  }

  Color? getColor(MapDataSource? dataSource, MapFeature feature) {
    return _color;
  }
}

class _MapThemeValue extends MapTheme {
  _MapThemeValue(
      {Color? color,
      Color? contourColor,
      LabelVisibility? labelVisibility,
      LabelStyleBuilder? labelStyleBuilder,
      required this.key,
      Map<dynamic, Color>? colors})
      : this._colors = colors,
        super(
            color: color,
            contourColor: contourColor,
            labelVisibility: labelVisibility,
            labelStyleBuilder: labelStyleBuilder);

  final String key;
  final Map<dynamic, Color>? _colors;

  bool hasValue() {
    return (_colors != null && _colors!.isNotEmpty) || super.hasValue();
  }

  @override
  Color? getColor(MapDataSource? dataSource, MapFeature feature) {
    if (_colors != null) {
      dynamic? value = feature.getValue(key);
      if (value != null && _colors!.containsKey(value)) {
        return _colors![value]!;
      }
    }
    return super.getColor(dataSource, feature);
  }
}

class _MapThemeRule extends MapTheme {
  _MapThemeRule(
      {Color? color,
      Color? contourColor,
      LabelVisibility? labelVisibility,
      LabelStyleBuilder? labelStyleBuilder,
      required List<ColorRule> colorRules})
      : this._colorRules = colorRules,
        super(
            color: color,
            contourColor: contourColor,
            labelVisibility: labelVisibility,
            labelStyleBuilder: labelStyleBuilder);

  final List<ColorRule> _colorRules;

  @override
  bool hasValue() {
    //It is not possible to know in advance, it depends on the rule.
    return true;
  }

  @override
  Color? getColor(MapDataSource? dataSource, MapFeature feature) {
    Color? color;
    for (ColorRule rule in _colorRules) {
      color = rule(feature);
      if (color != null) {
        break;
      }
    }
    return color != null ? color : super.getColor(dataSource, feature);
  }
}

class _MapThemeGradient extends MapTheme {
  _MapThemeGradient(
      {Color? color,
      Color? contourColor,
      LabelVisibility? labelVisibility,
      LabelStyleBuilder? labelStyleBuilder,
      required this.min,
      required this.max,
      required this.key,
      required this.colors})
      : super(
            color: color,
            contourColor: contourColor,
            labelVisibility: labelVisibility,
            labelStyleBuilder: labelStyleBuilder);

  final double? min;
  final double? max;
  final String key;
  final List<Color> colors;

  @override
  bool hasValue() {
    //It is not possible to know in advance, it depends on the property values.
    return true;
  }

  @override
  Color? getColor(MapDataSource? dataSource, MapFeature feature) {
    double? min = this.min;
    double? max = this.max;

    if (min == null || max == null) {
      PropertyLimits? propertyLimits = dataSource?.getPropertyLimits(key);
      if (propertyLimits != null) {
        if (min == null) {
          min = propertyLimits.min;
        }
        if (max == null) {
          max = propertyLimits.max;
        }
      }
    }

    if (min != null && max != null) {
      dynamic? dynamicValue = feature.getValue(key);
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
