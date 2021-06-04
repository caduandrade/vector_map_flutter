import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_map/src/data_source.dart';
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
}

/// A [CircleMaker] builder.
class CircleMakerBuilder {
  /// Builds a fixed radius circle marker. The default [radius] value is [5].
  static MarkerBuilder fixed({double radius = 5}) {
    return _FixedRadius(radius: math.max(0, radius));
  }

  static MarkerBuilder mappedValues(
      {required String key, required Map<dynamic, double> radiuses}) {
    return _MappedValues(key: key, radiuses: radiuses);
  }

  static MarkerBuilder property({required String key}) {
    return _Property(key: key);
  }
}

/// Fixed radius [CircleMaker] builder.
class _FixedRadius extends MarkerBuilder {
  _FixedRadius({required this.radius});

  final double radius;

  @override
  Marker build(
      {required MapFeature feature,
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
      {required MapFeature feature,
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
      {required MapFeature feature,
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
