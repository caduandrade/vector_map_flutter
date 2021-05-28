import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class EnableHoverByValuePage extends StatefulWidget {
  @override
  EnableHoverByValuePageState createState() => EnableHoverByValuePageState();
}

class EnableHoverByValuePageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON, keys: ['Seq']);
    return DataSources(polygons: polygons);
  }

  @override
  Widget buildContent() {
    // coloring only the 'Darwin' feature
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.value(key: 'Seq', colors: {4: Colors.green}),
        hoverTheme: MapTheme(color: Colors.green[900]!));

    // enabling hover only for the 'Darwin' feature
    VectorMap map = VectorMap(
        layers: [layer],
        hoverRule: (feature) {
          return feature.getValue('Seq') == 4;
        });

    return map;
  }
}
