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
      double? fontSize,
      EdgeInsetsGeometry? padding = const EdgeInsets.all(8)})
      : this._height = height != null ? height : 150,
        this.fontSize = fontSize != null ? math.max(fontSize, 6) : 12,
        super(layer: layer, padding: padding) {
    if (layer.theme is MapGradientTheme == false) {
      throw VectorMapError('Theme must be a MapGradientTheme');
    }
  }

  final double _height;
  final double fontSize;

  @override
  Widget buildWidget(
      BuildContext context, double widgetWidth, double widgetHeight) {
    MapGradientTheme gradientTheme = layer.theme as MapGradientTheme;

    double availableHeight = widgetHeight;
    print(availableHeight);
    // double availableWidth = widgetWidth;
    if (padding != null) {
      availableHeight -= padding!.vertical;
      // availableWidth -= padding!.horizontal;
    }

    List<LayoutId> children = [];

    double gradientHeight = math.min(availableHeight, _height) - fontSize;

    if (gradientHeight > 4) {
      // only if there is available space
      Container gradient = Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: gradientTheme.colors)),
      );
      children.add(LayoutId(id: _Child.gradient, child: gradient));
    }
    return Container(
        padding: padding,
        child:
            CustomMultiChildLayout(children: children, delegate: _Delegate()));
  }
}

enum _Child { gradient, max, min }

class _Delegate extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    print(size);
    Size childSize = Size.zero;
    if (hasChild(_Child.gradient)) {
      childSize = layoutChild(_Child.gradient,
          BoxConstraints.tightFor(width: 30, height: size.height));
      print(childSize);
      positionChild(_Child.gradient, Offset(size.width - 30, 0));
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return false;
  }
}
