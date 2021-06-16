import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/addon/legend/legend.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/highlight_rule.dart';
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
      this.gradientWidth = 15,
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
    return _GradientLegendWidget(this);
  }
}

class _GradientLegendWidget extends StatefulWidget {
  const _GradientLegendWidget(this.legend);

  final GradientLegend legend;

  @override
  State<StatefulWidget> createState() => _GradientLegendState();
}

class _GradientLegendState extends State<_GradientLegendWidget> {
  _ValuePosition? valuePosition;

  @override
  Widget build(BuildContext context) {
    GradientLegend legend = widget.legend;

    MapGradientTheme gradientTheme = legend.layer.theme as MapGradientTheme;

    List<LayoutId> children = [];

    double? min = gradientTheme.min(legend.layer.dataSource);
    double? max = gradientTheme.max(legend.layer.dataSource);

    if (max != null && min != null) {
      children.add(LayoutId(
          id: _ChildId.gradient,
          child: _GradientBar(gradientTheme.key, min, max, gradientTheme.colors,
              _updateValuePosition)));

      children.add(LayoutId(id: _ChildId.max, child: _text(max.toString())));

      children.add(LayoutId(id: _ChildId.min, child: _text(min.toString())));

      if (valuePosition != null) {
        children.add(LayoutId(
            id: _ChildId.value,
            child: _text('≈ ' + valuePosition!.value.toString())));
      }
    }

    return Container(
      decoration: legend.decoration,
      margin: legend.margin,
      padding: legend.padding,
      child: CustomMultiChildLayout(
          children: children,
          delegate: _Delegate(
              legend: widget.legend, valuePosition: valuePosition?.y)),
      color: Colors.red.withOpacity(.5),
    );
  }

  Widget _text(String value) {
    return LimitedBox(
        child: Text(value.toString(),
            style: TextStyle(fontSize: widget.legend.fontSize),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        maxWidth: widget.legend.maxTextWidth);
  }

  _updateValuePosition(_ValuePosition? newValuePosition) {
    setState(() {
      valuePosition = newValuePosition;
    });
  }
}

typedef _ValuePositionUpdater = Function(_ValuePosition? position);

/// Holds the value and location in gradient bar
class _ValuePosition {
  _ValuePosition(this.y, this.value);

  final double y;
  final double value;
}

/// Gradient bar widget
class _GradientBar extends StatelessWidget {
  const _GradientBar(this.propertyKey, this.min, this.max, this.colors,
      this.valuePositionUpdater);

  final String propertyKey;
  final double min;
  final double max;
  final List<Color> colors;
  final _ValuePositionUpdater valuePositionUpdater;

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
          onHover: (event) => _highlightOn(
              context, constraints.maxHeight, event.localPosition.dy),
          onExit: (event) => _highlightOff(context));
    });
  }

  _highlightOn(BuildContext context, double maxHeight, double y) {
    VectorMapState? state = VectorMapState.of(context);
    if (state != null) {
      double range = max - min;
      double value = min + (((maxHeight - y) * range) / maxHeight);
      state.setHighlightRule(HighlightRule(
          key: propertyKey, value: value, rangePerPixel: range / maxHeight));
      valuePositionUpdater(_ValuePosition(y, value.roundToDouble()));
    }
  }

  _highlightOff(BuildContext context) {
    VectorMapState? state = VectorMapState.of(context);
    if (state != null) {
      state.setHighlightRule(null);
      valuePositionUpdater(null);
    }
  }
}

enum _ChildId { gradient, max, min, value }

class _Delegate extends MultiChildLayoutDelegate {
  final GradientLegend legend;
  final double? valuePosition;

  _Delegate({required this.legend, this.valuePosition});

  @override
  Size getSize(BoxConstraints constraints) {
    if (legend.maxTextWidth == double.infinity) {
      return Size(constraints.maxWidth, legend.gradientHeight);
    }
    return Size(legend.gap + legend.maxTextWidth + legend.gradientWidth,
        legend.gradientHeight);
  }

  @override
  void performLayout(Size size) {
    Size childSize = Size.zero;

    double textHeight = 0;
    if (hasChild(_ChildId.max)) {
      childSize = _layoutChild(_ChildId.max, size);
      textHeight = childSize.height;
      positionChild(
          _ChildId.max,
          Offset(
              size.width - childSize.width - legend.gap - legend.gradientWidth,
              0));
    }

    if (hasChild(_ChildId.gradient)) {
      double gradientHeight = math.max(0, size.height - textHeight);
      childSize = layoutChild(
          _ChildId.gradient,
          BoxConstraints.tightFor(
              width: legend.gradientWidth, height: gradientHeight));
      positionChild(_ChildId.gradient,
          Offset(size.width - childSize.width, textHeight / 2));
    }

    if (hasChild(_ChildId.min)) {
      childSize = _layoutChild(_ChildId.min, size);
      textHeight = childSize.height;
      positionChild(
          _ChildId.min,
          Offset(
              size.width - childSize.width - legend.gap - legend.gradientWidth,
              size.height - textHeight));
    }

    if (hasChild(_ChildId.value) && valuePosition != null) {
      childSize = _layoutChild(_ChildId.value, size);
      textHeight = childSize.height;
      positionChild(
          _ChildId.value,
          Offset(
              size.width - childSize.width - legend.gap - legend.gradientWidth,
              valuePosition!));
    }
  }

  Size _layoutChild(_ChildId id, Size size) {
    if (legend.maxTextWidth == double.infinity) {
      return layoutChild(
          id,
          BoxConstraints.tightFor(
              width: size.width - legend.gradientWidth - legend.gap));
    } else {
      return layoutChild(
          id,
          BoxConstraints.tightFor(
              width: math.min(legend.maxTextWidth,
                  size.width - legend.gradientWidth - legend.gap)));
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return false;
  }
}
