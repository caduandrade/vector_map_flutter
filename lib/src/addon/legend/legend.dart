import 'package:flutter/widgets.dart';
import 'package:vector_map/src/addon/map_addon.dart';
import 'package:vector_map/src/data/map_layer.dart';

/// Abstract legend
abstract class Legend extends MapAddon {
  /// Builds a legend
  Legend(
      {required this.layer,
      EdgeInsetsGeometry? padding,
      EdgeInsetsGeometry? margin,
      Decoration? decoration})
      : super(padding: padding, decoration: decoration, margin: margin);
  final MapLayer layer;
}
