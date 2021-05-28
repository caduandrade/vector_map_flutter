import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:multi_split_view/multi_split_view.dart';
import 'package:vector_map/vector_map.dart';

void main() {
  runApp(ExampleWidget());
}

class ExampleWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ExampleState();
}

class ExampleState extends State<ExampleWidget> {
  MapDataSource? _dataSource;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/brazil_uf.json').then((geojson) {
      _loadDataSource(geojson);
    });
  }

  _loadDataSource(String geojson) async {
    MapDataSource dataSource = await MapDataSource.geoJSON(
        geojson: geojson, keys: ['GEOCODIGO'], parseToNumber: ['GEOCODIGO']);
    setState(() {
      _dataSource = dataSource;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (_dataSource != null) {
      content = _buildMap(_dataSource!);
    } else {
      content = Text('Loading...');
    }

    MultiSplitView multiSplitView =
        MultiSplitView(children: [content, Container(width: 50)]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: Scaffold(
          body: Center(
              child: SizedBox(width: 600, height: 500, child: multiSplitView))),
    );
  }

  Widget _buildMap(MapDataSource dataSource) {
    return VectorMap(layers: [
      MapLayer(
          dataSource: dataSource,
          theme: MapTheme.gradient(
              contourColor: Colors.green[800],
              key: 'GEOCODIGO',
              colors: [Colors.yellow, Colors.lightGreen]),
          hoverTheme: MapTheme(color: Colors.green[900]))
    ]);
  }
}
