import 'package:demo/menu.dart';
import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class GradientPage extends StatefulWidget {
  @override
  GradientPageState createState() => GradientPageState();
}

class GradientPageState extends ExamplePageState {
  @override
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, keys: ['Seq']);
    return dataSource;
  }

  @override
  List<MenuItem> buildMenuItems() {
    return [
      MenuItem('Auto min max', _autoMinMax),
      MenuItem('Min max', _minMax)
    ];
  }

  Widget _autoMinMax() {
    if (dataSource == null) {
      return VectorMap();
    }

    VectorMapTheme theme = VectorMapTheme.gradient(
        contourColor: Colors.white,
        key: 'Seq',
        colors: [Colors.blue, Colors.yellow, Colors.red]);

    VectorMap map = VectorMap(dataSource: dataSource, theme: theme);

    return map;
  }

  Widget _minMax() {
    VectorMapTheme theme = VectorMapTheme.gradient(
        contourColor: Colors.white,
        key: 'Seq',
        min: 3,
        max: 9,
        colors: [Colors.blue, Colors.yellow, Colors.red]);

    VectorMap map = VectorMap(dataSource: dataSource, theme: theme);

    return map;
  }
}
