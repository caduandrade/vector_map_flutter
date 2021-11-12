import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/vector_map_controller.dart';

class DurationDebugger extends ChangeNotifier {
  DurationDebugger(VoidCallback listener) {
    addListener(listener);
  }

  int _milliseconds = 0;
  int get milliseconds => _milliseconds;

  DateTime? _lastStartTime;

  void clear() {
    _milliseconds = 0;
    _lastStartTime = null;
  }

  void open() {
    _lastStartTime = DateTime.now();
  }

  closeAndInc() {
    if (_lastStartTime != null) {
      DateTime end = DateTime.now();
      Duration duration = end.difference(_lastStartTime!);
      _milliseconds += duration.inMilliseconds;
      _lastStartTime = null;
      notifyListeners();
    }
  }
}

class MapDebugger extends ChangeNotifier {
  MapDebugger() {
    drawableBuildDuration = DurationDebugger(notifyListeners);
    bufferBuildDuration = DurationDebugger(notifyListeners);
  }

  int _layersCount = 0;
  int _chunksCount = 0;
  int _featuresCount = 0;
  int _originalPointsCount = 0;
  int _simplifiedPointsCount = 0;
  Offset? _mouseHoverWorld;
  Offset? _mouseHoverCanvas;

  late DurationDebugger drawableBuildDuration;
  late DurationDebugger bufferBuildDuration;

  void updateLayers(List<DrawableLayer> drawableLayers, int chunksCount) {
    _layersCount = drawableLayers.length;
    _chunksCount = chunksCount;
    for (DrawableLayer drawableLayer in drawableLayers) {
      MapLayer layer = drawableLayer.layer;
      _featuresCount += layer.dataSource.features.length;
      _originalPointsCount += layer.dataSource.pointsCount;
    }
    _simplifiedPointsCount = 0;
    notifyListeners();
  }

  void updateMouseHover({Offset? worldCoordinate, Offset? locationOnCanvas}) {
    this._mouseHoverWorld = worldCoordinate;
    this._mouseHoverCanvas = locationOnCanvas;
    notifyListeners();
  }

  void updateSimplifiedPointsCount(int simplifiedPointsCount) {
    _simplifiedPointsCount = simplifiedPointsCount;
    notifyListeners();
  }
}

class MapDebuggerWidget extends StatefulWidget {
  MapDebuggerWidget(VectorMapController? controller)
      : this.debugger = controller?.debugger;

  final MapDebugger? debugger;

  @override
  State<StatefulWidget> createState() {
    return MapDebuggerState();
  }
}

class MapDebuggerState extends State<MapDebuggerWidget> {
  ScrollController _controller = ScrollController();

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
    if (widget.debugger == null) {
      return Container();
    }
    MapDebugger d = widget.debugger!;

    int drawableBuildDuration = d.drawableBuildDuration.milliseconds;
    int bufferBuildDuration = d.bufferBuildDuration.milliseconds;
    int multiResolutionDuration = drawableBuildDuration + bufferBuildDuration;

    return SingleChildScrollView(
        controller: _controller,
        child: Column(children: [
          _title('Quantities'),
          _int('Layers: ', d._layersCount),
          _int(' • Chunks: ', d._chunksCount),
          _int('Features: ', d._featuresCount),
          _int('Original points: ', d._originalPointsCount),
          _int('Simplified points: ', d._simplifiedPointsCount),
          _title('Last durations'),
          _milliseconds('Drawables build: ', multiResolutionDuration),
          _milliseconds(' • Simplified geometries: ', drawableBuildDuration),
          _milliseconds(' • Buffers: ', bufferBuildDuration),
          _title('Cursor location'),
          _offset('Canvas: ', d._mouseHoverCanvas),
          _offset('World: ', d._mouseHoverWorld)
        ], crossAxisAlignment: CrossAxisAlignment.start));
  }

  Widget _title(String text) {
    return Padding(
        padding: EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: Text(text,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
  }

  Widget _milliseconds(String label, int value) {
    return _item(label, formatInt(value) + ' ms');
  }

  Widget _int(String label, int value) {
    return _item(label, formatInt(value));
  }

  Widget _offset(String label, Offset? offset) {
    if (offset == null) {
      return _item(label, '');
    }
    return _item(label, offset.dx.toString() + ', ' + offset.dy.toString());
  }

  Widget _item(String label, String value) {
    return Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
        child: RichText(
          text: new TextSpan(
            style: TextStyle(fontSize: 12),
            children: <TextSpan>[
              new TextSpan(text: label),
              new TextSpan(
                  text: value,
                  style: new TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ));
  }

  @override
  void initState() {
    super.initState();
    widget.debugger?.addListener(_refresh);
  }

  @override
  void didUpdateWidget(MapDebuggerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.debugger?.removeListener(_refresh);
    widget.debugger?.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.debugger?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    setState(() {
      // rebuild
    });
  }
}
