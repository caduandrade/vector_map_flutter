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
  MapDebugger debugger = MapDebugger();

  @override
  void initState() {
    super.initState();
    String asset = 'assets/south_america.json';
    rootBundle.loadString(asset).then((geoJson) {
      _loadDataSource(geoJson);
    });
  }

  _loadDataSource(String geoJson) async {
    MapDataSource dataSource = await MapDataSource.geoJson(geoJson: geoJson);
    setState(() {
      _controller = VectorMapController(layers: [
        MapLayer(
            dataSource: dataSource,
            highlightTheme: MapHighlightTheme(color: Colors.green[900]))
      ], debugger: debugger);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (_controller != null) {
      VectorMap map = VectorMap(controller: _controller);
      Widget buttons = SingleChildScrollView(
          child: Row(children: [
        _buildFitButton(),
        SizedBox(width: 8),
        _buildModeButton(),
        SizedBox(width: 8),
        _buildZoomInButton(),
        SizedBox(width: 8),
        _buildZoomOutButton()
      ]));

      Widget buttonsAndMap = Column(children: [
        Padding(child: buttons, padding: EdgeInsets.only(bottom: 8)),
        Expanded(child: map)
      ]);

      content = Row(children: [
        Expanded(child: buttonsAndMap),
        SizedBox(
            child: Padding(
                child: MapDebuggerWidget(debugger),
                padding: EdgeInsets.all(16)),
            width: 200)
      ]);
    } else {
      content = Center(child: Text('Loading...'));
    }

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
        home: Scaffold(
            body: SafeArea(
                child: Padding(child: content, padding: EdgeInsets.all(8)))));
  }

  Widget _buildFitButton() {
    return ElevatedButton(child: Text('Fit'), onPressed: _onFit);
  }

  void _onFit() {
    _controller?.fit();
  }

  Widget _buildModeButton() {
    return ElevatedButton(child: Text('Change mode'), onPressed: _onMode);
  }

  void _onMode() {
    VectorMapMode mode = _controller!.mode == VectorMapMode.autoFit
        ? VectorMapMode.panAndZoom
        : VectorMapMode.autoFit;
    _controller!.mode = mode;
  }

  Widget _buildZoomInButton() {
    return ElevatedButton(child: Text('Zoom in'), onPressed: _onZoomIn);
  }

  void _onZoomIn() {
    _controller!.zoomOnCenter(true);
  }

  Widget _buildZoomOutButton() {
    return ElevatedButton(child: Text('Zoom out'), onPressed: _onZoomOut);
  }

  void _onZoomOut() {
    _controller!.zoomOnCenter(false);
  }
}
