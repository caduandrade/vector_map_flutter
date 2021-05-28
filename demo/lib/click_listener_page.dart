import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class ClickListenerPage extends StatefulWidget {
  @override
  ClickListenerPageState createState() => ClickListenerPageState();
}

class ClickListenerPageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
    return DataSources(polygons: polygons);
  }

  @override
  Widget buildContent() {
    MapLayer layer = MapLayer(
        dataSource: polygons, hoverTheme: MapTheme(color: Colors.grey[800]!));

    VectorMap map = VectorMap(
        layers: [layer],
        clickListener: (feature) {
          print(feature.id);
        });
    return map;
  }
}
