import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class ColorByValuePage extends StatefulWidget {
  @override
  ColorByValuePageState createState() => ColorByValuePageState();
}

class ColorByValuePageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons = await MapDataSource.geoJSON(
        geojson: polygonsGeoJSON, keys: ['Seq'], labelKey: 'Seq');
    return DataSources(polygons: polygons);
  }

  @override
  Widget buildContent() {
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.value(
            contourColor: Colors.white,
            labelVisibility: (feature) => true,
            key: 'Seq',
            colors: {
              2: Colors.green,
              4: Colors.red,
              6: Colors.orange,
              8: Colors.blue
            }));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }
}
