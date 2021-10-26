import 'dart:convert';

import 'package:vector_map/src/data/geometries.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/error.dart';

/// Generic GeoJSON reader.
class _GeoJSONReaderBase {
  void _checkKeyOn(Map<String, dynamic> map, String key) {
    if (map.containsKey(key) == false) {
      throw VectorMapError.keyNotFound(key);
    }
  }

  MapGeometry _readGeometry(bool hasParent, Map<String, dynamic> map) {
    _checkKeyOn(map, 'type');
    final type = map['type'];
    switch (type) {
      //TODO other geometries
      case 'Point':
        return _readPoint(map);
      case 'MultiPoint':
        throw UnimplementedError();
      case 'LineString':
        return _readLineString(map);
      case 'MultiLineString':
        throw UnimplementedError();
      case 'Polygon':
        return _readPolygon(map);
      case 'MultiPolygon':
        return _readMultiPolygon(map);
      default:
        if (hasParent) {
          throw VectorMapError.invalidGeometryType(type);
        } else {
          throw VectorMapError.invalidType(type);
        }
    }
  }

  MapGeometry _readPoint(Map<String, dynamic> map) {
    _checkKeyOn(map, 'coordinates');
    List coordinates = map['coordinates'];
    if (coordinates.length == 2) {
      double x = _toDouble(coordinates[0]);
      double y = _toDouble(coordinates[1]);
      return MapPoint(x, y);
    }

    throw VectorMapError(
        'Expected 2 coordinates but received ' + coordinates.length.toString());
  }

  MapGeometry _readLineString(Map<String, dynamic> map) {
    _checkKeyOn(map, 'coordinates');
    List coordinates = map['coordinates'];
    List<MapPoint> points = [];
    for (List xy in coordinates) {
      double x = _toDouble(xy[0]);
      double y = _toDouble(xy[1]);
      points.add(MapPoint(x, y));
    }
    return MapLineString(points);
  }

  MapGeometry _readPolygon(Map<String, dynamic> map) {
    late MapLinearRing externalRing;
    List<MapLinearRing> internalRings = [];

    _checkKeyOn(map, 'coordinates');
    List rings = map['coordinates'];
    for (int i = 0; i < rings.length; i++) {
      List<MapPoint> points = [];
      List ring = rings[i];
      for (List xy in ring) {
        double x = _toDouble(xy[0]);
        double y = _toDouble(xy[1]);
        points.add(MapPoint(x, y));
      }
      if (i == 0) {
        externalRing = MapLinearRing(points);
      } else {
        internalRings.add(MapLinearRing(points));
      }
    }

    return MapPolygon(externalRing, internalRings);
  }

  MapGeometry _readMultiPolygon(Map<String, dynamic> map) {
    _checkKeyOn(map, 'coordinates');
    List polygons = map['coordinates'];

    List<MapPolygon> mapPolygons = [];
    for (List rings in polygons) {
      late MapLinearRing externalRing;
      List<MapLinearRing> internalRings = [];

      for (int i = 0; i < rings.length; i++) {
        List<MapPoint> points = [];
        List ring = rings[i];
        for (List xy in ring) {
          double x = _toDouble(xy[0]);
          double y = _toDouble(xy[1]);
          points.add(MapPoint(x, y));
        }
        if (i == 0) {
          externalRing = MapLinearRing(points);
        } else {
          internalRings.add(MapLinearRing(points));
        }
      }
      MapPolygon polygon = MapPolygon(externalRing, internalRings);
      mapPolygons.add(polygon);
    }

    return MapMultiPolygon(mapPolygons);
  }

  /// Parses a dynamic coordinate to [double].
  double _toDouble(dynamic coordinate) {
    if (coordinate is double) {
      return coordinate;
    } else if (coordinate is int) {
      return coordinate.toDouble();
    }
    // The coordinate shouldn't be a String but since it is, tries to parse.
    return double.parse(coordinate.toString());
  }
}

enum ColorValueFormat { hex }

/// Properties read.
class _Properties {
  _Properties({this.label, this.values});

  /// Label value extracted from [labelKey].
  final String? label;
  final Map<String, dynamic>? values;
}

/// [MapFeature] reader
///
/// The [keys] argument defines which properties must be loaded.
/// The [parseToNumber] argument defines which properties will have numeric
/// values in quotes parsed to numbers.
class MapFeatureReader extends _GeoJSONReaderBase {
  MapFeatureReader(
      {this.labelKey,
      this.keys,
      this.parseToNumber,
      this.colorKey,
      this.colorValueFormat = ColorValueFormat.hex});

  final List<MapFeature> _list = [];

  final String? labelKey;
  final Set<String>? keys;
  final Set<String>? parseToNumber;
  final String? colorKey;
  final ColorValueFormat colorValueFormat;

  Future<List<MapFeature>> read(String geojson) async {
    Map<String, dynamic> map = json.decode(geojson);
    await _readMap(map);
    return _list;
  }

  Future<void> _readMap(Map<String, dynamic> map) async {
    _checkKeyOn(map, 'type');

    final type = map['type'];

    if (type == 'FeatureCollection') {
      _checkKeyOn(map, 'features');
      //TODO check if it is a Map?
      for (Map<String, dynamic> featureMap in map['features']) {
        _readFeature(featureMap);
      }
    } else if (type == 'GeometryCollection') {
    } else if (type == 'Feature') {
      _readFeature(map);
    } else {
      MapGeometry geometry = _readGeometry(false, map);
      _addFeature(geometry: geometry);
    }
  }

  void _readFeature(Map<String, dynamic> map) {
    _checkKeyOn(map, 'geometry');
    Map<String, dynamic> geometryMap = map['geometry'];
    MapGeometry geometry = _readGeometry(true, geometryMap);
    _Properties? properties;
    if ((labelKey != null || keys != null || colorKey != null) &&
        map.containsKey('properties')) {
      Map<String, dynamic> propertiesMap = map['properties'];
      properties = _readProperties(propertiesMap);
    }
    _addFeature(geometry: geometry, properties: properties);
  }

  _Properties _readProperties(Map<String, dynamic> map) {
    String? label;
    Map<String, dynamic>? values;
    if (labelKey != null && map.containsKey(labelKey)) {
      // converting dynamic to String
      label = map[labelKey].toString();
    }
    if (keys != null) {
      if (keys!.isNotEmpty) {
        Map<String, dynamic> valuesTmp = Map<String, dynamic>();
        for (String key in keys!) {
          if (map.containsKey(key)) {
            dynamic value = map[key];
            if (parseToNumber != null &&
                parseToNumber!.contains(key) &&
                value is String) {
              value = double.parse(value);
            }
            valuesTmp[key] = value;
          }
        }
        if (valuesTmp.isNotEmpty) {
          values = valuesTmp;
        }
      }
    }
    return _Properties(label: label, values: values);
  }

  void _addFeature({required MapGeometry geometry, _Properties? properties}) {
    _list.add(MapFeature(
        id: _list.length + 1,
        geometry: geometry,
        properties: properties?.values,
        label: properties?.label));
  }
}

/// GeoJSON geometry reader.
class MapGeometryReader extends _GeoJSONReaderBase {
  final List<MapGeometry> _list = [];

  Future<List<MapGeometry>> geoJSON(String geojson) async {
    Map<String, dynamic> map = json.decode(geojson);
    await _readMap(map);
    return _list;
  }

  Future<void> _readMap(Map<String, dynamic> map) async {
    _checkKeyOn(map, 'type');

    final type = map['type'];

    if (type == 'FeatureCollection') {
      _checkKeyOn(map, 'features');
      //TODO check if it is a Map?
      for (Map<String, dynamic> featureMap in map['features']) {
        _readFeature(featureMap);
      }
    } else if (type == 'GeometryCollection') {
    } else if (type == 'Feature') {
      _readFeature(map);
    } else {
      MapGeometry geometry = _readGeometry(false, map);
      _list.add(geometry);
    }
  }

  void _readFeature(Map<String, dynamic> map) {
    _checkKeyOn(map, 'geometry');
    Map<String, dynamic> geometryMap = map['geometry'];
    MapGeometry geometry = _readGeometry(true, geometryMap);
    _list.add(geometry);
  }
}
