import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class ColorByValuePage extends StatefulWidget {
  @override
  ColorByValuePageState createState() => ColorByValuePageState();
}

class ColorByValuePageState extends ExamplePageState {
  @override
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, keys: ['Seq']);
    return dataSource;
  }

  @override
  Widget buildContent() {
    VectorMapTheme theme = VectorMapTheme.value(
        contourColor: Colors.white,
        key: 'Seq',
        colors: {
          2: Colors.green,
          4: Colors.red,
          6: Colors.orange,
          8: Colors.blue
        });

    VectorMap map = VectorMap(dataSource: dataSource, theme: theme);

    return map;
  }
}
