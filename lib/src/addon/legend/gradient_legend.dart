import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/addon/legend/legend.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/theme/map_gradient_theme.dart';

/// Legend for [MapGradientTheme]
class GradientLegend extends Legend {
  /// Builds a [GradientLegend].
  ///
  /// The layer's theme must be a [MapGradientTheme].
  GradientLegend(
      {required MapLayer layer,
      this.height = 150,
      double? fontSize,
      this.gradientWidth = 25,
      this.maxTextWidth = 80,
      this.gap = 8})
      : this.fontSize = fontSize != null ? math.max(fontSize, 6) : 12,
        super(layer: layer) {
    if (layer.theme is MapGradientTheme == false) {
      throw VectorMapError('Theme must be a MapGradientTheme');
    }
  }

  final double gap;
  final double maxTextWidth;
  final double gradientWidth;

  @override
  final double height;

  final double fontSize;

  @override
  double get width {
    if (maxTextWidth == double.infinity) {
      return double.infinity;
    }
    return gap + maxTextWidth + gradientWidth;
  }

  @override
  Widget buildWidget(
      BuildContext context, double availableWidth, double availableHeight) {
    MapGradientTheme gradientTheme = layer.theme as MapGradientTheme;

    List<LayoutId> children = [];

    children.add(LayoutId(
        id: _Child.gradient,
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: gradientTheme.colors)),
        )));

    double? min = gradientTheme.min(layer.dataSource);
    double? max = gradientTheme.max(layer.dataSource);

    if (max != null) {
      children.add(LayoutId(
          id: _Child.max,
          child: LimitedBox(child: _text(max), maxWidth: maxTextWidth)));
    }

    return Container(
      child: CustomMultiChildLayout(
          children: children,
          delegate: _Delegate(
              gap: gap,
              gradientWidth: gradientWidth,
              maxTextWidth: maxTextWidth)),
      color: Colors.red.withOpacity(.5),
    );
  }

  Text _text(double value) {
    return Text(value.toString(),
        style: TextStyle(fontSize: fontSize),
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis);
  }
}

enum _Child { gradient, max, min }

class _Delegate extends MultiChildLayoutDelegate {
  final double gap;
  final double maxTextWidth;
  final double gradientWidth;

  _Delegate(
      {required this.gap,
      required this.maxTextWidth,
      required this.gradientWidth});

  @override
  void performLayout(Size size) {
    Size childSize = Size.zero;

    double fontHeight = 0;
    if (hasChild(_Child.max)) {
      if (maxTextWidth == double.infinity) {
        childSize = layoutChild(_Child.max,
            BoxConstraints.tightFor(width: size.width - gradientWidth - gap));
      } else {
        childSize = layoutChild(
            _Child.max,
            BoxConstraints.tightFor(
                width:
                    math.min(maxTextWidth, size.width - gradientWidth - gap)));
      }
      fontHeight = childSize.height;

      positionChild(_Child.max,
          Offset(size.width - childSize.width - gap - gradientWidth, 0));

      if (hasChild(_Child.gradient)) {
        double gradientHeight = math.max(0, size.height - fontHeight);
        childSize = layoutChild(
            _Child.gradient,
            BoxConstraints.tightFor(
                width: gradientWidth, height: gradientHeight));
        positionChild(_Child.gradient,
            Offset(size.width - childSize.width, fontHeight / 2));
      }
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return false;
  }
}
