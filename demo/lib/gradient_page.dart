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
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON, keys: ['Seq']);
    return DataSources(polygons: polygons);
  }

  @override
  List<MenuItem> buildMenuItems() {
    return [
      MenuItem('Auto min max', _autoMinMax),
      MenuItem('Min max', _minMax)
    ];
  }

  Widget _autoMinMax() {
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.gradient(
            contourColor: Colors.white,
            key: 'Seq',
            colors: [Colors.blue, Colors.yellow, Colors.red]));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }

  Widget _minMax() {
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.gradient(
            contourColor: Colors.white,
            key: 'Seq',
            min: 3,
            max: 9,
            colors: [Colors.blue, Colors.yellow, Colors.red]));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }
}
