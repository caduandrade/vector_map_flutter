import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class ParserPage extends StatefulWidget {
  @override
  ParserPageState createState() => ParserPageState();
}

class ParserPageState extends ExamplePageState {
  @override
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource = await VectorMapDataSource.geoJSON(
        geojson: geojson,
        keys: ['Seq', 'Rnd'],
        parseToNumber: ['Rnd'],
        labelKey: 'Rnd');
    return dataSource;
  }

  @override
  Widget buildContent() {
    VectorMap map = VectorMap(
        dataSource: dataSource,
        theme: VectorMapTheme.gradient(
            labelVisibility: (feature) => true,
            key: 'Rnd',
            colors: [Colors.blue, Colors.red]));
    return map;
  }
}
