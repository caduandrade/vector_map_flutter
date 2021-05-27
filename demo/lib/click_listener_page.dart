import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class ClickListenerPage extends StatefulWidget {
  @override
  ClickListenerPageState createState() => ClickListenerPageState();
}

class ClickListenerPageState extends ExamplePageState {
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
        hoverTheme: VectorMapTheme(color: Colors.grey[800]!),
        clickListener: (feature) {
          print(feature.id);
        });
    return map;
  }
}
