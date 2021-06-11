import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_map/src/data_reader.dart';
import 'package:vector_map/src/matrix.dart';
import 'package:vector_map/src/simplifier.dart';

/// A representation of a real-world object on a map.
class MapFeature {
  MapFeature(
      {required this.id,
      required this.geometry,
      Map<String, dynamic>? properties,
      this.color,
      this.label})
      : this._properties = properties;

  final int id;
  final String? label;
  final Map<String, dynamic>? _properties;
  final Color? color;
  final MapGeometry geometry;

  dynamic getValue(String key) {
    if (_properties != null && _properties!.containsKey(key)) {
      return _properties![key];
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
}

/// Stores the number limits, max and min, for a given feature property.
class PropertyLimits {
  double _max;
  double _min;

  PropertyLimits(double value)
      : this._max = value,
        this._min = value;

  double get max => _max;

  double get min => _min;

  expand(double value) {
    _max = math.max(_max, value);
    _min = math.min(_min, value);
  }
}

/// [VectorMap] data source.
class MapDataSource {
  MapDataSource._(
      {required this.features,
      required this.bounds,
      required this.pointsCount,
      Map<String, PropertyLimits>? limits})
      : this._limits = limits;

  final UnmodifiableMapView<int, MapFeature> features;
  final Rect bounds;
  final int pointsCount;
  final Map<String, PropertyLimits>? _limits;

  /// Create a [MapDataSource] from a list of [MapFeature].
  static MapDataSource fromFeatures(List<MapFeature> features) {
    Rect boundsFromGeometry = Rect.zero;
    int pointsCount = 0;
    if (features.isNotEmpty) {
      boundsFromGeometry = features.first.geometry.bounds;
    }
    Map<String, PropertyLimits> limits = Map<String, PropertyLimits>();
    Map<int, MapFeature> featuresMap = Map<int, MapFeature>();
    for (MapFeature feature in features) {
      featuresMap[feature.id] = feature;
      pointsCount += feature.geometry.pointsCount;
      boundsFromGeometry =
          boundsFromGeometry.expandToInclude(feature.geometry.bounds);
      if (feature._properties != null) {
        feature._properties!.entries.forEach((entry) {
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
    Rect boundsFromGeometry = Rect.zero;
    int pointsCount = 0;
    if (geometries.isNotEmpty) {
      boundsFromGeometry = geometries.first.bounds;
    }
    Map<int, MapFeature> featuresMap = Map<int, MapFeature>();
    int id = 1;
    for (MapGeometry geometry in geometries) {
      featuresMap[id] = MapFeature(id: id, geometry: geometry);
      pointsCount += geometry.pointsCount;
      boundsFromGeometry = boundsFromGeometry.expandToInclude(geometry.bounds);
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

/// Stores a simplified path generated from the original [MapFeature] geometry.
class SimplifiedPath {
  SimplifiedPath(this.path, this.pointsCount);

  final Path path;
  final int pointsCount;
}

/// Abstract map geometry.
mixin MapGeometry {
  Rect get bounds;

  int get pointsCount;
}

/// Point geometry.
class MapPoint extends Offset with MapGeometry {
  MapPoint(double x, double y) : super(x, y);

  double get x => dx;

  double get y => dy;

  @override
  String toString() {
    return 'MapPoint{x: $x, y: $y}';
  }

  @override
  Rect get bounds => Rect.fromLTWH(x, y, 0, 0);

  @override
  int get pointsCount => 1;
}

/// Line string geometry.
class MapLineString with MapGeometry {
  final UnmodifiableListView<MapPoint> points;
  final Rect bounds;

  MapLineString._(this.points, this.bounds);

  factory MapLineString.coordinates(List<double> coordinates) {
    List<MapPoint> points = [];
    for (int i = 0; i < coordinates.length; i = i + 2) {
      if (i < coordinates.length - 1) {
        double x = coordinates[i];
        double y = coordinates[i + 1];
        points.add(MapPoint(x, y));
      }
    }
    return MapLineString(points);
  }

  factory MapLineString(List<MapPoint> points) {
    //TODO exception for insufficient number of points?
    MapPoint first = points.first;
    double left = first.dx;
    double right = first.dx;
    double top = first.dy;
    double bottom = first.dy;

    for (int i = 1; i < points.length; i++) {
      MapPoint point = points[i];
      left = math.min(point.dx, left);
      right = math.max(point.dx, right);
      bottom = math.max(point.dy, bottom);
      top = math.min(point.dy, top);
    }
    Rect bounds = Rect.fromLTRB(left, top, right, bottom);
    return MapLineString._(UnmodifiableListView<MapPoint>(points), bounds);
  }

  @override
  int get pointsCount => points.length;

  SimplifiedPath toSimplifiedPath(
      CanvasMatrix canvasMatrix, GeometrySimplifier simplifier) {
    Path path = Path();
    List<MapPoint> simplifiedPoints = simplifier.simplify(canvasMatrix, points);
    for (int i = 0; i < simplifiedPoints.length; i++) {
      MapPoint point = simplifiedPoints[i];
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return SimplifiedPath(path, simplifiedPoints.length);
  }
}

/// Line ring geometry.
class MapLinearRing with MapGeometry {
  final UnmodifiableListView<MapPoint> points;
  final Rect bounds;

  MapLinearRing._(this.points, this.bounds);

  factory MapLinearRing.coordinates(List<double> coordinates) {
    List<MapPoint> points = [];
    for (int i = 0; i < coordinates.length; i = i + 2) {
      if (i < coordinates.length - 1) {
        double x = coordinates[i];
        double y = coordinates[i + 1];
        points.add(MapPoint(x, y));
      }
    }
    return MapLinearRing(points);
  }

  factory MapLinearRing(List<MapPoint> points) {
    //TODO exception for insufficient number of points?
    MapPoint first = points.first;
    double left = first.dx;
    double right = first.dx;
    double top = first.dy;
    double bottom = first.dy;

    for (int i = 1; i < points.length; i++) {
      MapPoint point = points[i];
      left = math.min(point.dx, left);
      right = math.max(point.dx, right);
      bottom = math.max(point.dy, bottom);
      top = math.min(point.dy, top);
    }
    Rect bounds = Rect.fromLTRB(left, top, right, bottom);
    return MapLinearRing._(UnmodifiableListView<MapPoint>(points), bounds);
  }

  @override
  int get pointsCount => points.length;

  SimplifiedPath toSimplifiedPath(
      CanvasMatrix canvasMatrix, GeometrySimplifier simplifier) {
    Path path = Path();
    List<MapPoint> simplifiedPoints = simplifier.simplify(canvasMatrix, points);
    for (int i = 0; i < simplifiedPoints.length; i++) {
      MapPoint point = simplifiedPoints[i];
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return SimplifiedPath(path, simplifiedPoints.length);
  }
}

/// Polygon geometry.
class MapPolygon with MapGeometry {
  final MapLinearRing externalRing;
  final UnmodifiableListView<MapLinearRing> internalRings;
  final Rect bounds;

  MapPolygon._(this.externalRing, this.internalRings, this.bounds);

  factory MapPolygon.coordinates(List<double> coordinates) {
    List<MapPoint> externalPoints = [];
    List<MapLinearRing> internalRings = [];
    List<MapPoint> points = [];
    for (int i = 0; i < coordinates.length; i = i + 2) {
      if (i < coordinates.length - 1) {
        double x = coordinates[i];
        double y = coordinates[i + 1];
        points.add(MapPoint(x, y));
        if (points.length >= 3) {
          if (points.first.x == x && points.first.y == y) {
            // closing ring
            if (externalPoints.length == 0) {
              externalPoints = points;
            } else {
              internalRings.add(MapLinearRing(points));
            }
            points = [];
          }
        }
      }
    }
    return MapPolygon(MapLinearRing(externalPoints), internalRings);
  }

  factory MapPolygon(
      MapLinearRing externalRing, List<MapLinearRing>? internalRings) {
    Rect bounds = externalRing.bounds;

    List<MapLinearRing> internal = internalRings != null ? internalRings : [];
    for (MapLinearRing linearRing in internal) {
      bounds = bounds.expandToInclude(linearRing.bounds);
    }
    return MapPolygon._(
        externalRing, UnmodifiableListView<MapLinearRing>(internal), bounds);
  }

  @override
  int get pointsCount => _getPointsCount();

  int _getPointsCount() {
    int count = externalRing.pointsCount;
    for (MapLinearRing ring in internalRings) {
      count += ring.pointsCount;
    }
    return count;
  }

  SimplifiedPath toSimplifiedPath(
      CanvasMatrix canvasMatrix, GeometrySimplifier simplifier) {
    Path path = Path()..fillType = PathFillType.evenOdd;

    SimplifiedPath simplifiedPath =
        externalRing.toSimplifiedPath(canvasMatrix, simplifier);
    int pointsCount = simplifiedPath.pointsCount;
    path.addPath(simplifiedPath.path, Offset.zero);
    for (MapLinearRing ring in internalRings) {
      simplifiedPath = ring.toSimplifiedPath(canvasMatrix, simplifier);
      pointsCount += simplifiedPath.pointsCount;
      path.addPath(simplifiedPath.path, Offset.zero);
    }
    return SimplifiedPath(path, pointsCount);
  }
}

/// Multi polygon geometry.
class MapMultiPolygon with MapGeometry {
  final UnmodifiableListView<MapPolygon> polygons;
  final Rect bounds;

  MapMultiPolygon._(this.polygons, this.bounds);

  factory MapMultiPolygon(List<MapPolygon> polygons) {
    Rect bounds = polygons.first.bounds;
    for (int i = 1; i < polygons.length; i++) {
      bounds = bounds.expandToInclude(polygons[i].bounds);
    }
    return MapMultiPolygon._(
        UnmodifiableListView<MapPolygon>(polygons), bounds);
  }

  @override
  int get pointsCount => _getPointsCount();

  /// Gets the count of points.
  int _getPointsCount() {
    int count = 0;
    for (MapPolygon polygon in polygons) {
      count += polygon.pointsCount;
    }
    return count;
  }
}
