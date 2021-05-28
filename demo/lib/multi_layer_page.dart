import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class MultiLayerPage extends StatefulWidget {
  @override
  MultiLayerPageState createState() => MultiLayerPageState();
}

class MultiLayerPageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
    MapDataSource points = await MapDataSource.geoJSON(geojson: pointsGeoJSON);
    return DataSources(polygons: polygons, points: points);
  }

  @override
  Widget buildContent() {
    MapTheme hoverTheme = MapTheme(color: Colors.green);

    MapLayer polygonsLayer =
        MapLayer(dataSource: polygons, hoverTheme: hoverTheme);
    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(color: Colors.black),
        hoverTheme: hoverTheme);

    VectorMap map = VectorMap(layers: [polygonsLayer, pointsLayer]);
    return map;
  }
}
