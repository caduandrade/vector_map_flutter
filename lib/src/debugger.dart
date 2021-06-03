import 'package:flutter/cupertino.dart';
import 'package:vector_map/src/layer.dart';
import 'package:vector_map/src/map_resolution.dart';

class MapDebugger extends ChangeNotifier {
  int _layersCount = 0;
  int _featuresCount = 0;
  int _originalPointsCount = 0;
  int _simplifiedPointsCount = 0;

  int _lastPaintableBuildDuration = 0;
  int _nextPaintableBuildDuration = 0;
  DateTime? _paintableBuildStart;

  int _lastBufferBuildDuration = 0;
  int _nextBufferBuildDuration = 0;
  DateTime? _bufferBuildStart;

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

  clearCountPaintableBuildDuration() {
    _nextPaintableBuildDuration = 0;
    _paintableBuildStart = null;
  }

  updateCountPaintableBuildDuration() {
    _lastPaintableBuildDuration = _nextPaintableBuildDuration;
    _paintableBuildStart = null;
    notifyListeners();
  }

  markPaintableBuildStart() {
    _paintableBuildStart = DateTime.now();
  }

  markPaintableBuildEnd() {
    if (_paintableBuildStart != null) {
      DateTime end = DateTime.now();
      Duration duration = end.difference(_paintableBuildStart!);
      _nextPaintableBuildDuration += duration.inMilliseconds;
    }
  }

  clearCountBufferBuildDuration() {
    _nextBufferBuildDuration = 0;
    _bufferBuildStart = null;
  }

  updateCountBufferBuildDuration() {
    _lastBufferBuildDuration = _nextBufferBuildDuration;
    _bufferBuildStart = null;
    notifyListeners();
  }

  markBufferBuildStart() {
    _bufferBuildStart = DateTime.now();
  }

  markBufferBuildEnd() {
    if (_bufferBuildStart != null) {
      DateTime end = DateTime.now();
      Duration duration = end.difference(_bufferBuildStart!);
      _nextBufferBuildDuration += duration.inMilliseconds;
    }
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
    Duration paintableDuration =
        Duration(milliseconds: widget.debugger._lastPaintableBuildDuration);
    Duration bufferDuration =
        Duration(milliseconds: widget.debugger._lastBufferBuildDuration);

    return Column(children: [
      Text('Layers: ' + formatInt(widget.debugger._layersCount)),
      Text('Features: ' + formatInt(widget.debugger._featuresCount)),
      Text('Original points: ' +
          formatInt(widget.debugger._originalPointsCount)),
      Text('Simplified points: ' +
          formatInt(widget.debugger._simplifiedPointsCount)),
      Text('Last paintable build duration: ' + paintableDuration.toString()),
      Text('Last buffer build duration: ' + bufferDuration.toString())
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
