import 'dart:collection';
import 'dart:ui';

import 'package:vector_map/src/data/geometries.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/property_limits.dart';
import 'package:vector_map/src/data_reader.dart';

/// [VectorMap] data source.
class MapDataSource {
  MapDataSource._(
      {required this.features,
      required this.bounds,
      required this.pointsCount,
      Map<String, PropertyLimits>? limits})
      : this._limits = limits;

  final UnmodifiableMapView<int, MapFeature> features;
  final Rect? bounds;
  final int pointsCount;
  final Map<String, PropertyLimits>? _limits;

  /// Create a [MapDataSource] from a list of [MapFeature].
  static MapDataSource fromFeatures(List<MapFeature> features) {
    Rect? boundsFromGeometry;
    int pointsCount = 0;
    if (features.isNotEmpty) {
      boundsFromGeometry = features.first.geometry.bounds;
    }
    Map<String, PropertyLimits> limits = Map<String, PropertyLimits>();
    Map<int, MapFeature> featuresMap = Map<int, MapFeature>();
    for (MapFeature feature in features) {
      featuresMap[feature.id] = feature;
      pointsCount += feature.geometry.pointsCount;
      if (boundsFromGeometry == null) {
        boundsFromGeometry = feature.geometry.bounds;
      } else {
        boundsFromGeometry =
            boundsFromGeometry.expandToInclude(feature.geometry.bounds);
      }
      if (feature.properties != null) {
        feature.properties!.entries.forEach((entry) {
          dynamic value = entry.value;
          double? doubleValue;
          if (value is int) {
            doubleValue = value.toDouble();
          } else if (value is double) {
            doubleValue = value;
          }
          if (doubleValue != null) {
            String key = entry.key;
            if (limits.containsKey(key)) {
              PropertyLimits propertyLimits = limits[key]!;
              propertyLimits.expand(doubleValue);
            } else {
              limits[key] = PropertyLimits(doubleValue);
            }
          }
        });
      }
    }

    return MapDataSource._(
        features: UnmodifiableMapView<int, MapFeature>(featuresMap),
        bounds: boundsFromGeometry,
        pointsCount: pointsCount,
        limits: limits.isNotEmpty ? limits : null);
  }

  /// Loads a [MapDataSource] from GeoJSON.
  ///
  /// Geometries are always loaded.
  /// The [keys] argument defines which properties must be loaded.
  /// The [parseToNumber] argument defines which properties will have
  /// numeric values in quotes parsed to numbers.
  static Future<MapDataSource> geoJSON(
      {required String geojson,
      String? labelKey,
      List<String>? keys,
      List<String>? parseToNumber,
      String? colorKey,
      ColorValueFormat colorValueFormat = ColorValueFormat.hex}) async {
    MapFeatureReader reader = MapFeatureReader(
        labelKey: labelKey,
        keys: keys != null ? keys.toSet() : null,
        parseToNumber: parseToNumber != null ? parseToNumber.toSet() : null,
        colorKey: colorKey,
        colorValueFormat: colorValueFormat);

    List<MapFeature> features = await reader.read(geojson);
    return fromFeatures(features);
  }

  /// Loads a [MapDataSource] from geometries.
  /// [MapDataSource] features will have no properties.
  factory MapDataSource.geometries(List<MapGeometry> geometries) {
    Rect? boundsFromGeometry;
    int pointsCount = 0;
    Map<int, MapFeature> featuresMap = Map<int, MapFeature>();
    int id = 1;
    for (MapGeometry geometry in geometries) {
      featuresMap[id] = MapFeature(id: id, geometry: geometry);
      pointsCount += geometry.pointsCount;
      if (boundsFromGeometry == null) {
        boundsFromGeometry = geometry.bounds;
      } else {
        boundsFromGeometry =
            boundsFromGeometry.expandToInclude(geometry.bounds);
      }
      id++;
    }

    return MapDataSource._(
        features: UnmodifiableMapView<int, MapFeature>(featuresMap),
        bounds: boundsFromGeometry,
        pointsCount: pointsCount);
  }

  PropertyLimits? getPropertyLimits(String key) {
    if (_limits != null && _limits!.containsKey(key)) {
      return _limits![key]!;
    }
    return null;
  }
}
