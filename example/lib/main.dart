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
  VectorMapController? _controller;

  @override
  void initState() {
    super.initState();
    String asset = 'assets/south_america.json';
    rootBundle.loadString(asset).then((geojson) {
      _loadDataSource(geojson);
    });
  }

  _loadDataSource(String geojson) async {
    MapDataSource dataSource = await MapDataSource.geoJSON(geojson: geojson);
    setState(() {
      _controller = VectorMapController(layers: [
        MapLayer(
            dataSource: dataSource,
            highlightTheme: MapHighlightTheme(color: Colors.green[900]))
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? map;
    if (_controller != null) {
      map = VectorMap(controller: _controller);
    } else {
      map = Center(child: Text('Loading...'));
    }

    Widget buttons =
        SingleChildScrollView(child: Row(children: [_buildFitButton()]));

    Widget content = Column(children: [
      Padding(child: buttons, padding: EdgeInsets.only(bottom: 8)),
      Expanded(child: map)
    ]);

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
        home: Scaffold(
            body: Padding(child: content, padding: EdgeInsets.all(8))));
  }

  bool _isButtonsEnabled() {
    return _controller != null;
  }

  Widget _buildFitButton() {
    return ElevatedButton(
        child: Text('Fit'), onPressed: _isButtonsEnabled() ? _onFit : null);
  }

  void _onFit() {
    _controller?.fit();
  }
}
