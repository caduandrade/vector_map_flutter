import 'package:flutter/cupertino.dart';
import 'package:vector_map/src/layer.dart';
import 'package:vector_map/src/map_resolution.dart';

class MapDebugger extends ChangeNotifier {
  int _layersCount = 0;
  int _featuresCount = 0;
  int _originalPointsCount = 0;
  int _simplifiedPointsCount = 0;

  initialize(List<MapLayer> layers) {
    _layersCount = layers.length;
    for (MapLayer layer in layers) {
      _featuresCount += layer.dataSource.features.length;
      _originalPointsCount += layer.dataSource.pointsCount;
    }
    notifyListeners();
  }

  updateMapResolution(MapResolution mapResolution) {
    _simplifiedPointsCount = mapResolution.pointsCount;
    notifyListeners();
  }
}

class MapDebuggerWidget extends StatefulWidget {
  MapDebuggerWidget(this.debugger);

  final MapDebugger debugger;

  @override
  State<StatefulWidget> createState() {
    return MapDebuggerState();
  }
}

class MapDebuggerState extends State<MapDebuggerWidget> {
  String formatInt(int value) {
    String str = value.toString();
    String fmt = '';
    int indexGroup = 3 - str.length % 3;
    if (indexGroup == 3) {
      indexGroup = 0;
    }
    for (int i = 0; i < str.length; i++) {
      fmt += str.substring(i, i + 1);
      indexGroup++;
      if (indexGroup == 3 && i < str.length - 1) {
        fmt += ',';
        indexGroup = 0;
      }
    }
    return fmt;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('Layers: ' + formatInt(widget.debugger._layersCount)),
      Text('Features: ' + formatInt(widget.debugger._featuresCount)),
      Text('Original points: ' +
          formatInt(widget.debugger._originalPointsCount)),
      Text('Simplified points: ' +
          formatInt(widget.debugger._simplifiedPointsCount))
    ], crossAxisAlignment: CrossAxisAlignment.start);
  }

  @override
  void initState() {
    super.initState();
    widget.debugger.addListener(_refresh);
  }

  @override
  void didUpdateWidget(MapDebuggerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.debugger.removeListener(_refresh);
    widget.debugger.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.debugger.removeListener(_refresh);
    super.dispose();
  }

  _refresh() {
    Future.delayed(Duration.zero, () async {
      setState(() {
        // rebuild
      });
    });
  }
}
