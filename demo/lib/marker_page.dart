import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class MarkerPage extends StatefulWidget {
  @override
  MarkerPageState createState() => MarkerPageState();
}

class MarkerPageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource points = await MapDataSource.geoJSON(geojson: pointsGeoJSON);
    return DataSources(points: points);
  }

  @override
  Widget buildContent() {
    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(
            color: Colors.black,
            markerBuilder: CircleMakerBuilder(radius: 15)));

    VectorMap map = VectorMap(layers: [pointsLayer]);
    return map;
  }
}
