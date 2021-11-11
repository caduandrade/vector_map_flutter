import 'package:vector_map/src/map_highlight.dart';

/// Defines the map API.
/// Through this class, plugins and addons will be able to automate the map.
abstract class VectorMapApi {
  /// Removes the current highlight.
  void clearHighlight();

  /// Sets a new highlight on the map.
  void setHighlight(MapHighlight newHighlight);
}
