import 'dart:collection';

import 'package:vector_map/src/data/geometries.dart';

/// A representation of a real-world object on a map.
class MapFeature {
  MapFeature(
      {required this.id,
      required this.geometry,
      Map<String, dynamic>? properties,
      this.label})
      : this.properties =
            properties != null ? UnmodifiableMapView(properties) : null;

  final int id;
  final String? label;
  final UnmodifiableMapView<String, dynamic>? properties;
  final MapGeometry geometry;

  dynamic getValue(String key) {
    if (properties != null && properties!.containsKey(key)) {
      return properties![key];
    }
    return null;
  }

  double? getDoubleValue(String key) {
    dynamic d = getValue(key);
    if (d != null) {
      if (d is double) {
        return d;
      } else if (d is int) {
        return d.toDouble();
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapFeature && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
