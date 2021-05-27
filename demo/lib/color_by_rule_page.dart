import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class ColorByRulePage extends StatefulWidget {
  @override
  ColorByRulePageState createState() => ColorByRulePageState();
}

class ColorByRulePageState extends ExamplePageState {
  @override
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource = await VectorMapDataSource.geoJSON(
        geojson: geojson, keys: ['Name', 'Seq']);
    return dataSource;
  }

  @override
  Widget buildContent() {
    VectorMapTheme theme =
        VectorMapTheme.rule(contourColor: Colors.white, colorRules: [
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
    ]);

    VectorMap map = VectorMap(dataSource: dataSource, theme: theme);

    return map;
  }
}
