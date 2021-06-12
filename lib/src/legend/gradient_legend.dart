import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/legend/legend.dart';
import 'package:vector_map/src/theme/map_gradient_theme.dart';

/// Legend for [MapGradientTheme]
class GradientLegend extends Legend {
  /// Builds a [GradientLegend].
  ///
  /// The layer's theme must be a [MapGradientTheme].
  GradientLegend(
      {required MapLayer layer,
      double? height,
      EdgeInsetsGeometry? padding = const EdgeInsets.all(8)})
      : this._height = height != null ? height : 150,
        super(layer: layer, padding: padding) {
    if (layer.theme is MapGradientTheme == false) {
      throw VectorMapError('Theme must be a MapGradientTheme');
    }
  }

  final double _height;

  @override
  Widget buildWidget(
      BuildContext context, double widgetWidth, double widgetHeight) {
    MapGradientTheme gradientTheme = layer.theme as MapGradientTheme;

    double height = math.min(widgetHeight, _height);
    if(padding!=null){
      height-=padding!.vertical;
    }

    Container gradient = Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: gradientTheme.colors)),
        width: 25,
        height: height);

    return Container(padding: padding, child: gradient);
  }
}
