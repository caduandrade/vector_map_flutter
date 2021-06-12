import 'package:flutter/widgets.dart';

/// Allows to add components on the [VectorMap]
abstract class MapAddon {
  /// Builds the [Widget] for this addon
  Widget buildWidget(
      BuildContext context, double widgetWidth, double widgetHeight);
}
