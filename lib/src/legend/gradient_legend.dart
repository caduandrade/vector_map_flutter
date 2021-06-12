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
      EdgeInsetsGeometry? padding = const EdgeInsets.all(8)})
      : super(layer: layer, padding: padding) {
    if (layer.theme is MapGradientTheme == false) {
      throw VectorMapError('Theme must be a MapGradientTheme');
    }
  }

  @override
  Widget buildWidget(BuildContext context) {
    MapGradientTheme gradientTheme = layer.theme as MapGradientTheme;

    Container gradient = Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter,
        end:   Alignment.topCenter,colors: gradientTheme.colors)), width: 30, height: 200);

    return Container(padding: padding, child:gradient);
  }
}
