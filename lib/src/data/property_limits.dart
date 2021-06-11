import 'dart:math' as math;

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
