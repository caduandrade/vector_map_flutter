import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/marker.dart';

/// Defines a circle marker to be painted on the map.
class CircleMaker extends Marker {
  CircleMaker(
      {required Offset offset,
      required double radius,
      required double scaledRadius})
      : this._bounds = Rect.fromLTWH(offset.dx - scaledRadius,
            offset.dy - scaledRadius, scaledRadius * 2, scaledRadius * 2),
        this._radius = radius,
        super(offset: offset);

  final Rect _bounds;
  final double _radius;

  @override
  bool contains(Offset offset) {
    return _bounds.contains(offset);
  }

  @override
  drawMarkerOn(Canvas canvas, Paint paint, Offset offset, double scale) {
    canvas.drawCircle(offset, _radius / scale, paint);
  }

  @override
  Rect getBounds() {
    return _bounds;
  }

  @override
  bool get visible => _radius > 0 ? true : false;

  @override
  bool get hasFill => true;
}

/// A [CircleMaker] builder.
class CircleMakerBuilder {
  /// Builds a fixed radius circle marker. The default [radius] value is [5].
  static MarkerBuilder fixed({double radius = 5}) {
    return _FixedRadius(radius: math.max(0, radius));
  }

  /// Builds a circle marker by mapping a property value to a radius.
  static MarkerBuilder map(
      {required String key, required Map<dynamic, double> radiuses}) {
    return _MappedValues(key: key, radiuses: radiuses);
  }

  /// Builds a circle marker using property values as radiuses.
  /// The type of the values must be numeric.
  static MarkerBuilder property({required String key}) {
    return _Property(key: key);
  }

  /// Builds a circle marker by proportionally mapping property
  /// values to defined minimum and maximum values.
  static MarkerBuilder proportion(
      {required String key,
      required double minRadius,
      required double maxRadius}) {
    if (maxRadius <= minRadius) {
      throw VectorMapError('maxRadius must be bigger than minRadius');
    }
    return _Proportion(key: key, minRadius: minRadius, maxRadius: maxRadius);
  }
}

/// Fixed radius [CircleMaker] builder.
class _FixedRadius extends MarkerBuilder {
  _FixedRadius({required this.radius});

  final double radius;

  @override
  Marker build(
      {required MapDataSource dataSource,
      required MapFeature feature,
      required Offset offset,
      required double scale}) {
    return CircleMaker(
        offset: offset, radius: radius, scaledRadius: radius / scale);
  }
}

class _MappedValues extends MarkerBuilder {
  _MappedValues({required this.key, required this.radiuses});

  final String key;
  final Map<dynamic, double> radiuses;

  @override
  Marker build(
      {required MapDataSource dataSource,
      required MapFeature feature,
      required Offset offset,
      required double scale}) {
    double r = 0;
    dynamic value = feature.getValue(key);
    if (value != null && radiuses.containsKey(value)) {
      r = math.max(0, radiuses[value]!);
    }
    return CircleMaker(offset: offset, radius: r, scaledRadius: r / scale);
  }
}

class _Property extends MarkerBuilder {
  _Property({required this.key});

  final String key;

  @override
  Marker build(
      {required MapDataSource dataSource,
      required MapFeature feature,
      required Offset offset,
      required double scale}) {
    double r = 0;
    dynamic dynamicValue = feature.getValue(key);
    if (dynamicValue is int) {
      r = math.max(0, dynamicValue.toDouble());
    } else if (dynamicValue is double) {
      r = math.max(0, dynamicValue);
    }

    return CircleMaker(offset: offset, radius: r, scaledRadius: r / scale);
  }
}

class _Proportion extends MarkerBuilder {
  _Proportion(
      {required this.key, required this.minRadius, required this.maxRadius});

  final String key;
  final double minRadius;
  final double maxRadius;

  @override
  Marker build(
      {required MapDataSource dataSource,
      required MapFeature feature,
      required Offset offset,
      required double scale}) {
    double radius = 0;

    PropertyLimits? propertyLimits = dataSource.getPropertyLimits(key);
    if (propertyLimits != null) {
      dynamic dynamicValue = feature.getValue(key);
      if (dynamicValue is int) {
        radius = _radius(
            propertyLimits.min, propertyLimits.max, dynamicValue.toDouble());
      } else if (dynamicValue is double) {
        radius = _radius(propertyLimits.min, propertyLimits.max, dynamicValue);
      }
    }

    return CircleMaker(
        offset: offset, radius: radius, scaledRadius: radius / scale);
  }

  double _radius(double minValue, double maxValue, double dynamicValue) {
    double valueRange = maxValue - minValue;
    double p = ((dynamicValue - minValue) / valueRange);
    return minRadius + ((maxRadius - minRadius) * p);
  }
}
