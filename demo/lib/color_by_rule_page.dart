import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class ColorByRulePage extends StatefulWidget {
  @override
  ColorByRulePageState createState() => ColorByRulePageState();
}

class ColorByRulePageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons = await MapDataSource.geoJSON(
        geojson: polygonsGeoJSON, keys: ['Name', 'Seq']);
    return DataSources(polygons: polygons);
  }

  @override
  Widget buildContent() {
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.rule(contourColor: Colors.white, colorRules: [
          (feature) {
            String? value = feature.getValue('Name');
            return value == 'Faraday' ? Colors.red : null;
          },
          (feature) {
            double? value = feature.getDoubleValue('Seq');
            return value != null && value < 3 ? Colors.green : null;
          },
          (feature) {
            double? value = feature.getDoubleValue('Seq');
            return value != null && value > 9 ? Colors.blue : null;
          }
        ]));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }
}
