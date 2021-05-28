import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class ParserPage extends StatefulWidget {
  @override
  ParserPageState createState() => ParserPageState();
}

class ParserPageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons = await MapDataSource.geoJSON(
        geojson: polygonsGeoJSON,
        keys: ['Seq', 'Rnd'],
        parseToNumber: ['Rnd'],
        labelKey: 'Rnd');
    return DataSources(polygons: polygons);
  }

  @override
  Widget buildContent() {
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.gradient(
            labelVisibility: (feature) => true,
            key: 'Rnd',
            colors: [Colors.blue, Colors.red]));

    VectorMap map = VectorMap(layers: [layer]);
    return map;
  }
}
