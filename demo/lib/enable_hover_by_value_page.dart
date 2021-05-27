import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class EnableHoverByValuePage extends StatefulWidget {
  @override
  EnableHoverByValuePageState createState() => EnableHoverByValuePageState();
}

class EnableHoverByValuePageState extends ExamplePageState {
  @override
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, keys: ['Seq']);
    return dataSource;
  }

  @override
  Widget buildContent() {
    // coloring only the 'Darwin' feature
    VectorMapTheme theme =
        VectorMapTheme.value(key: 'Seq', colors: {4: Colors.green});
    VectorMapTheme hoverTheme = VectorMapTheme(color: Colors.green[900]!);

    // enabling hover only for the 'Darwin' feature
    VectorMap map = VectorMap(
      dataSource: dataSource,
      theme: theme,
      hoverTheme: hoverTheme,
      hoverRule: (feature) {
        return feature.getValue('Seq') == 4;
      },
    );

    return map;
  }
}
