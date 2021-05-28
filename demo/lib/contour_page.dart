import 'package:demo/menu.dart';
import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class ContourPage extends StatefulWidget {
  @override
  ContourPageState createState() => ContourPageState();
}

class ContourPageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
    return DataSources(polygons: polygons);
  }

  @override
  List<MenuItem> buildMenuItems() {
    return [
      MenuItem('Thickness', _thickness),
      MenuItem('No contour', _noContour)
    ];
  }

  Widget _thickness() {
    VectorMap map = VectorMap(
        layers: [MapLayer(dataSource: polygons)], contourThickness: 3);

    return map;
  }

  Widget _noContour() {
    VectorMap map = VectorMap(
        layers: [MapLayer(dataSource: polygons)], contourThickness: 0);

    return map;
  }
}
