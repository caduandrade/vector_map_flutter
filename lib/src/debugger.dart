import 'package:flutter/cupertino.dart';
import 'package:vector_map/src/layer.dart';
import 'package:vector_map/src/map_resolution.dart';

class DurationDebugger {
  int _lastDuration = 0;
  int _nextDuration = 0;
  DateTime? _lastStartTime;

  clear() {
    _nextDuration = 0;
    _lastStartTime = null;
  }

  update() {
    _lastDuration = _nextDuration;
    _lastStartTime = null;
  }

  openDuration() {
    _lastStartTime = DateTime.now();
  }

  closeDuration() {
    if (_lastStartTime != null) {
      DateTime end = DateTime.now();
      Duration duration = end.difference(_lastStartTime!);
      _nextDuration += duration.inMilliseconds;
    }
  }
}

class MapDebugger extends ChangeNotifier {
  int _layersCount = 0;
  int _featuresCount = 0;
  int _originalPointsCount = 0;
  int _simplifiedPointsCount = 0;

  DurationDebugger _paintableBuildDuration = DurationDebugger();
  DurationDebugger _bufferBuildDuration = DurationDebugger();

  DateTime? _initialMultiResolutionTime;
  Duration _multiResolutionDuration = Duration.zero;

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

  clearPaintableBuildDuration() {
    _paintableBuildDuration.clear();
  }

  updatePaintableBuildDuration() {
    _paintableBuildDuration.update();
    notifyListeners();
  }

  openPaintableBuildDuration() {
    _paintableBuildDuration.openDuration();
  }

  closePaintableBuildDuration() {
    _paintableBuildDuration.closeDuration();
  }

  clearBufferBuildDuration() {
    _bufferBuildDuration.clear();
  }

  updateBufferBuildDuration() {
    _bufferBuildDuration.update();
    notifyListeners();
  }

  openBufferBuildDuration() {
    _bufferBuildDuration.openDuration();
  }

  closeBufferBuildDuration() {
    _bufferBuildDuration.closeDuration();
  }

  openMultiResolutionTime() {
    _initialMultiResolutionTime = DateTime.now();
    _multiResolutionDuration = Duration.zero;
  }

  closeMultiResolutionTime() {
    if (_initialMultiResolutionTime != null) {
      DateTime end = DateTime.now();
      _multiResolutionDuration = end.difference(_initialMultiResolutionTime!);
      notifyListeners();
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
    Duration paintableDuration = Duration(
        milliseconds: widget.debugger._paintableBuildDuration._lastDuration);
    Duration bufferDuration = Duration(
        milliseconds: widget.debugger._bufferBuildDuration._lastDuration);

    return Column(children: [
      Text('Layers: ' + formatInt(widget.debugger._layersCount)),
      Text('Features: ' + formatInt(widget.debugger._featuresCount)),
      Text('Original points: ' +
          formatInt(widget.debugger._originalPointsCount)),
      Text('Simplified points: ' +
          formatInt(widget.debugger._simplifiedPointsCount)),
      Text('Last paintable build duration: ' + paintableDuration.toString()),
      Text('Last buffer build duration: ' + bufferDuration.toString()),
      Text('Last multi resolution duration: ' +
          widget.debugger._multiResolutionDuration.toString())
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
