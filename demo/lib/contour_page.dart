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
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson);
    return dataSource;
  }

  @override
  List<MenuItem> buildMenuItems() {
    return [
      MenuItem('Thickness', _thickness),
      MenuItem('No contour', _noContour)
    ];
  }

  Widget _thickness() {
    VectorMap map = VectorMap(dataSource: dataSource, contourThickness: 3);

    return map;
  }

  Widget _noContour() {
    VectorMap map = VectorMap(dataSource: dataSource, contourThickness: 0);

    return map;
  }
}
