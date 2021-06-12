import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/map_addon.dart';

/// Abstract legend
abstract class Legend extends MapAddon {
  /// Builds a legend
  Legend({required this.layer, this.padding});
  final MapLayer layer;
  final EdgeInsetsGeometry? padding;
}
