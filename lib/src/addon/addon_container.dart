import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:vector_map/src/addon/map_addon.dart';

/// Widget container for [MapAddon]
abstract class AddonContainer {
  AddonContainer._({required this.addon, required this.padding});

  final MapAddon addon;
  final EdgeInsetsGeometry padding;

  Positioned? buildPositioned(
      BuildContext context, double maxWidth, double maxHeight);

  static AddonContainer anchor(
      {required MapAddon addon, EdgeInsetsGeometry? padding}) {
    return _AddonAnchoredContainer(addon: addon, padding: padding);
  }
}

class _AddonAnchoredContainer extends AddonContainer {
  _AddonAnchoredContainer(
      {required MapAddon addon, EdgeInsetsGeometry? padding})
      : super._(
            addon: addon, padding: padding != null ? padding : EdgeInsets.zero);

  @override
  Positioned? buildPositioned(
      BuildContext context, double maxWidth, double maxHeight) {
    if (maxWidth - padding.horizontal < 6) {
      return null;
    }
    if (maxHeight - padding.vertical < 6) {
      return null;
    }

    double availableWidth = 0;
    if (addon.width == double.infinity) {
      availableWidth = maxWidth - padding.horizontal;
    } else {
      availableWidth = math.min(maxWidth - padding.horizontal, addon.width);
    }

    double availableHeight = 0;
    if (addon.height == double.infinity) {
      availableHeight = maxHeight - padding.vertical;
    } else {
      availableHeight = math.min(maxHeight - padding.vertical, addon.height);
    }

    Widget addonWidget = Padding(
        child: addon.buildWidget(context, availableWidth, availableHeight),
        padding: padding);

    double? left;
    double? top;
    double? right;
    double? bottom;
    double? width;
    double? height;

    bottom = 0;
    right = 0;
    if (addon.width == double.infinity) {
      left = 0;
    } else {
      width = availableWidth + padding.horizontal;
    }
    if (addon.height == double.infinity) {
      top = 0;
    } else {
      height = availableHeight + padding.vertical;
    }
    return Positioned(
        child: addonWidget,
        top: top,
        bottom: bottom,
        right: right,
        left: left,
        width: width,
        height: height);
  }
}
