import 'package:flutter/cupertino.dart';
import 'package:vector_map/src/layer.dart';

class MapDebugger extends ChangeNotifier {
  int _layersCount = 0;
  int _featuresCount = 0;
  int _originalPointsCount = 0;

  initialize(List<MapLayer> layers) {
    _layersCount = layers.length;
    for (MapLayer layer in layers) {
      _featuresCount += layer.dataSource.features.length;
      _originalPointsCount += layer.dataSource.pointsCount;
    }
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
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('Layers: ' + widget.debugger._layersCount.toString()),
      Text('Features: ' + widget.debugger._featuresCount.toString()),
      Text(
          'Original points: ' + widget.debugger._originalPointsCount.toString())
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
