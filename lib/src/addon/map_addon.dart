import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/vector_map_api.dart';

/// Allows to add components on the [VectorMap]
abstract class MapAddon {
  MapAddon({this.padding, this.decoration, this.margin});

  /// Empty space to inscribe inside the [decoration]. The [MapAddon] widget, if any, is
  /// placed inside this padding.
  ///
  /// This padding is in addition to any padding inherent in the [decoration];
  /// see [Decoration.padding].
  final EdgeInsetsGeometry? padding;

  /// The decoration to paint behind the [MapAddon] widget.
  final Decoration? decoration;

  /// Empty space to surround the [decoration] and [MapAddon] widget.
  final EdgeInsetsGeometry? margin;

  /// Builds the [Widget] for this addon
  Widget buildWidget(
      {required BuildContext context,
      required VectorMapApi mapApi,
      MapFeature? hover});
}
