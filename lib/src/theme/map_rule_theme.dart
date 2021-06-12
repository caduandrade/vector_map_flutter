import 'package:flutter/rendering.dart';
import 'package:vector_map/src/data/map_data_source.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/drawable/marker.dart';
import 'package:vector_map/src/theme/map_theme.dart';

/// Theme for colors by rule.
///
/// The feature color is obtained from the first rule that returns
/// a non-null color.
/// If all rules return a null color, the default color is used.
class MapRuleTheme extends MapTheme {
  MapRuleTheme(
      {Color? color,
      Color? contourColor,
      LabelVisibility? labelVisibility,
      LabelStyleBuilder? labelStyleBuilder,
      MarkerBuilder? markerBuilder,
      required List<ColorRule> colorRules})
      : this._colorRules = colorRules,
        super(
            color: color,
            contourColor: contourColor,
            labelVisibility: labelVisibility,
            labelStyleBuilder: labelStyleBuilder,
            markerBuilder: markerBuilder);

  final List<ColorRule> _colorRules;

  @override
  bool hasValue() {
    //It is not possible to know in advance, it depends on the rule.
    return true;
  }

  @override
  Color? getColor(MapDataSource dataSource, MapFeature feature) {
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

/// Rule to obtain a color of a feature.
typedef ColorRule = Color? Function(MapFeature feature);
