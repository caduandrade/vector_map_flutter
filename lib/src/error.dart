/// Generic [VectorMap] error
class VectorMapError extends Error {
  final String _message;

  VectorMapError(this._message);

  VectorMapError.keyNotFound(String key)
      : this._message = 'Key "$key" not found.';

  VectorMapError.invalidType(String type)
      : this._message =
            'Invalid "$type" type. Must be: FeatureCollection, GeometryCollection, Feature, Point, MultiPoint, LineString, MultiLineString, Polygon or MultiPolygon.';

  VectorMapError.invalidGeometryType(String type)
      : this._message =
            'Invalid geometry "$type" type. Must be: GeometryCollection, Point, MultiPoint, LineString, MultiLineString, Polygon or MultiPolygon.';

  @override
  String toString() {
    return 'VectorMapError - $_message';
  }
}
