import 'package:vector_map/src/data_source.dart';

typedef FeatureClickListener = Function(MapFeature feature);

typedef HoverRule = bool Function(MapFeature feature);

typedef HoverListener = Function(MapFeature? feature);
