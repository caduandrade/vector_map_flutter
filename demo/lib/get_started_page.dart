import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class GetStartedPage extends StatefulWidget {
  @override
  GetStartedPageState createState() => GetStartedPageState();
}

class GetStartedPageState extends ExamplePageState {
  @override
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson);
    return dataSource;
  }

  @override
  Widget buildContent() {
    VectorMap map = VectorMap(dataSource: dataSource);
    return map;
  }
}
