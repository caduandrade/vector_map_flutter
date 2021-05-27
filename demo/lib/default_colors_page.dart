import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class DefaultColorsPage extends StatefulWidget {
  @override
  DefaultColorsPageState createState() => DefaultColorsPageState();
}

class DefaultColorsPageState extends ExamplePageState {
  @override
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson);
    return dataSource;
  }

  @override
  Widget buildContent() {
    VectorMap map = VectorMap(
        dataSource: dataSource,
        theme: VectorMapTheme(color: Colors.yellow, contourColor: Colors.red));

    return map;
  }
}
