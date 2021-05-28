import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class DefaultColorsPage extends StatefulWidget {
  @override
  DefaultColorsPageState createState() => DefaultColorsPageState();
}

class DefaultColorsPageState extends ExamplePageState {
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
        dataSource: polygons,
        theme: MapTheme(color: Colors.yellow, contourColor: Colors.red));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }
}
