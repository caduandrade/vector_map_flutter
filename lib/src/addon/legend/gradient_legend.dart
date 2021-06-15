import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/addon/legend/legend.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/theme/map_gradient_theme.dart';
import 'package:vector_map/src/vector_map.dart';

/// Legend for [MapGradientTheme]
class GradientLegend extends Legend {
  /// Builds a [GradientLegend].
  ///
  /// The layer's theme must be a [MapGradientTheme].
  GradientLegend(
      {required MapLayer layer,
      EdgeInsetsGeometry? padding,
      EdgeInsetsGeometry? margin,
      Decoration? decoration,
      this.gradientHeight = 150,
      double? fontSize,
      this.gradientWidth = 25,
      this.maxTextWidth = 80,
      this.gap = 8})
      : this.fontSize = fontSize != null ? math.max(fontSize, 6) : 12,
        super(
            layer: layer,
            padding: padding,
            margin: margin,
            decoration: decoration) {
    if (layer.theme is MapGradientTheme == false) {
      throw VectorMapError('Theme must be a MapGradientTheme');
    }
  }

  final double gap;
  final double maxTextWidth;
  final double gradientWidth;
  final double gradientHeight;
  final double fontSize;

  @override
  Widget buildWidget(BuildContext context, MapFeature? hover) {
    MapGradientTheme gradientTheme = layer.theme as MapGradientTheme;

    List<LayoutId> children = [];

    double? min = gradientTheme.min(layer.dataSource);
    double? max = gradientTheme.max(layer.dataSource);

    if (max != null && min != null) {
      children.add(LayoutId(
          id: _ChildId.gradient,
          child:
              _GradientBar(gradientTheme.key, min, max, gradientTheme.colors)));

      children.add(LayoutId(
          id: _ChildId.max,
          child: LimitedBox(child: _text(max), maxWidth: maxTextWidth)));

      children.add(LayoutId(
          id: _ChildId.min,
          child: LimitedBox(child: _text(min), maxWidth: maxTextWidth)));
    }

    return Container(
      decoration: decoration,
      margin: margin,
      padding: padding,
      child: CustomMultiChildLayout(
          children: children,
          delegate: _Delegate(
              gap: gap,
              gradientWidth: gradientWidth,
              gradientHeight: gradientHeight,
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

/// Gradient bar widget
class _GradientBar extends StatelessWidget {
  const _GradientBar(this.propertyKey, this.min, this.max, this.colors);

  final String propertyKey;
  final double min;
  final double max;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return MouseRegion(
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: colors)),
          ),
          onHover: (event) => _highlightOn(context, constraints.maxHeight,
              constraints.maxHeight - event.localPosition.dy),
          onExit: (event) => _highlightOff(context));
    });
  }

  _highlightOn(BuildContext context, double maxHeight, double y) {
    VectorMapState? state = VectorMapState.of(context);
    if (state != null) {
      double range = max - min;
      state.enableHighlightRule(
          key: propertyKey,
          value: min + ((y * range) / maxHeight),
          precision: range / maxHeight);
    }
  }

  _highlightOff(BuildContext context) {
    VectorMapState? state = VectorMapState.of(context);
    if (state != null) {
      state.disableHighlightRule();
    }
  }
}

enum _ChildId { gradient, max, min }

class _Delegate extends MultiChildLayoutDelegate {
  final double gap;
  final double maxTextWidth;
  final double gradientWidth;
  final double gradientHeight;

  _Delegate(
      {required this.gap,
      required this.maxTextWidth,
      required this.gradientWidth,
      required this.gradientHeight});

  @override
  Size getSize(BoxConstraints constraints) {
    if (maxTextWidth == double.infinity) {
      return Size(constraints.maxWidth, gradientHeight);
    }
    return Size(gap + maxTextWidth + gradientWidth, gradientHeight);
  }

  @override
  void performLayout(Size size) {
    Size childSize = Size.zero;

    double textHeight = 0;
    if (hasChild(_ChildId.max)) {
      childSize = _layoutChild(_ChildId.max, size);
      textHeight = childSize.height;
      positionChild(_ChildId.max,
          Offset(size.width - childSize.width - gap - gradientWidth, 0));
    }

    if (hasChild(_ChildId.gradient)) {
      double gradientHeight = math.max(0, size.height - textHeight);
      childSize = layoutChild(
          _ChildId.gradient,
          BoxConstraints.tightFor(
              width: gradientWidth, height: gradientHeight));
      positionChild(_ChildId.gradient,
          Offset(size.width - childSize.width, textHeight / 2));
    }

    if (hasChild(_ChildId.min)) {
      childSize = _layoutChild(_ChildId.min, size);
      textHeight = childSize.height;
      positionChild(
          _ChildId.min,
          Offset(size.width - childSize.width - gap - gradientWidth,
              size.height - textHeight));
    }
  }

  Size _layoutChild(_ChildId id, Size size) {
    if (maxTextWidth == double.infinity) {
      return layoutChild(
          id, BoxConstraints.tightFor(width: size.width - gradientWidth - gap));
    } else {
      return layoutChild(
          id,
          BoxConstraints.tightFor(
              width: math.min(maxTextWidth, size.width - gradientWidth - gap)));
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return false;
  }
}
