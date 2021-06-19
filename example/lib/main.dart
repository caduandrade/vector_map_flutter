import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
    rootBundle.loadString('assets/south_america.json').then((geojson) {
      _loadDataSource(geojson);
    });
  }

  _loadDataSource(String geojson) async {
    MapDataSource dataSource = await MapDataSource.geoJSON(geojson: geojson);
    setState(() {
      _dataSource = dataSource;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (_dataSource != null) {
      content = VectorMap(layers: [
        MapLayer(
            dataSource: _dataSource!,
            highlightTheme: MapHighlightTheme(color: Colors.green[900]))
      ]);
    } else {
      content = Text('Loading...');
    }

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
        home: Scaffold(
            body: Padding(child: content, padding: EdgeInsets.all(32))));
  }
}
