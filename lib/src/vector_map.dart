import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/addon/map_addon.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/drawable/drawable.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/drawable/drawable_layer_chunk.dart';
import 'package:vector_map/src/low_quality_mode.dart';
import 'package:vector_map/src/vector_map_controller.dart';
import 'package:vector_map/src/map_highlight.dart';
import 'package:vector_map/src/map_painter.dart';
import 'package:vector_map/src/vector_map_mode.dart';

/// Vector map widget.
class VectorMap extends StatefulWidget {
  VectorMap(
      {Key? key,
      this.controller,
      this.color,
      this.borderColor = Colors.black54,
      this.borderThickness = 1,
      this.layersPadding = const EdgeInsets.all(8),
      this.hoverRule,
      this.hoverListener,
      this.clickListener,
      this.addons,
      this.lowQualityMode})
      : super(key: key);

  final VectorMapController? controller;
  final Color? color;
  final Color? borderColor;
  final double? borderThickness;
  final EdgeInsetsGeometry? layersPadding;
  final HoverRule? hoverRule;
  final HoverListener? hoverListener;
  final FeatureClickListener? clickListener;
  final List<MapAddon>? addons;
  final LowQualityMode? lowQualityMode;

  @override
  State<StatefulWidget> createState() => _VectorMapState();
}

/// Holds the initial mouse location and matrix translate from the start of pan.
class _PanStart {
  _PanStart(
      {required this.mouseLocation,
      required this.translateX,
      required this.translateY});

  final Offset mouseLocation;
  final translateX;
  final translateY;
}

/// [VectorMap] state.
class _VectorMapState extends State<VectorMap> {
  VectorMapController _controller = VectorMapController();

  _PanStart? _panStart;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    }
    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant VectorMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        widget.controller != oldWidget.controller) {
      _controller.removeListener(_rebuild);
      _controller = widget.controller!;
      _controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    setState(() {
      // rebuild
    });
  }

  bool get _onPan => _panStart != null;

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (_controller.hasLayer) {
      Widget mapCanvas = _buildMapCanvas();
      if (widget.addons != null) {
        List<LayoutId> children = [LayoutId(id: 0, child: mapCanvas)];
        int count = 1;
        for (MapAddon addon in widget.addons!) {
          DrawableFeature? hover;
          if (_controller.highlight != null &&
              _controller.highlight is MapSingleHighlight) {
            hover =
                (_controller.highlight as MapSingleHighlight).drawableFeature;
          }
          children.add(LayoutId(
              id: count,
              child: addon.buildWidget(
                  context: context,
                  mapApi: _controller,
                  hover: hover?.feature)));
          count++;
        }
        content = CustomMultiChildLayout(
            children: children, delegate: _VectorMapLayoutDelegate(count));
      } else {
        content = mapCanvas;
      }
    } else {
      content = Center();
    }

    BoxBorder? border;
    if (widget.borderColor != null &&
        widget.borderThickness != null &&
        widget.borderThickness! > 0) {
      border = Border.all(
          color: widget.borderColor!, width: widget.borderThickness!);
    }
    Decoration? decoration;
    if (widget.color != null || border != null) {
      decoration = BoxDecoration(color: widget.color, border: border);
    }

    return Container(decoration: decoration, child: content);
  }

  /// Builds the canvas area
  Widget _buildMapCanvas() {
    LayoutBuilder layoutBuilder = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
        return Container();
      }

      Size canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

      _controller.setCanvasSize(canvasSize);

      MapPainter mapPainter = MapPainter(controller: _controller);
      Widget content = CustomPaint(painter: mapPainter, child: Container());
      content = _wrapWithHoverListener(content);
      if (_controller.mode == VectorMapMode.panAndZoom) {
        content = _wrapWithPanAndZoomListener(content);
      }
      if (widget.clickListener != null) {
        content = GestureDetector(child: content, onTap: () => _onClick());
      }
      return ClipRect(child: content);
    });

    return Container(child: layoutBuilder, padding: widget.layersPadding);
  }

  Widget _wrapWithHoverListener(Widget content) {
    return MouseRegion(
      child: content,
      onHover: (event) => _onHover(
          localPosition: event.localPosition,
          canvasToWorld: _controller.canvasToWorld),
      onExit: (event) {
        if (_controller.highlight != null) {
          _updateHover(null);
        }
        _controller.debugger?.updateMouseHover();
      },
    );
  }

  Widget _wrapWithPanAndZoomListener(Widget content) {
    return Listener(
        child: content,
        onPointerDown: (event) {
          _controller.notifyPanMode(start: true);
          if (_controller.highlight != null) {
            _updateHover(null);
          }
          setState(() {
            _panStart = _PanStart(
                mouseLocation: event.localPosition,
                translateX: _controller.translateX,
                translateY: _controller.translateY);
          });
        },
        onPointerMove: (event) {
          if (_panStart != null) {
            double diffX = _panStart!.mouseLocation.dx - event.localPosition.dx;
            double diffY = _panStart!.mouseLocation.dy - event.localPosition.dy;
            _controller.translate(
                _panStart!.translateX - diffX, _panStart!.translateY - diffY);
          }
        },
        onPointerUp: (event) {
          _controller.notifyPanMode(start: false);
          setState(() {
            _panStart = null;
          });
          _onHover(
              localPosition: event.localPosition,
              canvasToWorld: _controller.canvasToWorld);
        },
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            bool zoomIn = event.scrollDelta.dy < 0;
            _controller.zoomOnLocation(event.localPosition, zoomIn);
          }
        });
  }

  void _onClick() {
    MapHighlight? highlight = _controller.highlight;
    if (highlight != null &&
        highlight is MapSingleHighlight &&
        widget.clickListener != null) {
      if (highlight.drawableFeature != null) {
        widget.clickListener!(highlight.drawableFeature!.feature);
      }
    }
  }

  /// Triggered when a pointer moves over the map.
  void _onHover(
      {required Offset localPosition, required Matrix4 canvasToWorld}) {
    if (_onPan) {
      return;
    }
    Offset worldCoordinate =
        MatrixUtils.transformPoint(canvasToWorld, localPosition);

    _controller.debugger?.updateMouseHover(
        locationOnCanvas: localPosition, worldCoordinate: worldCoordinate);

    MapSingleHighlight? hoverHighlightRule;
    for (int layerIndex = _controller.layersCount - 1;
        layerIndex >= 0;
        layerIndex--) {
      DrawableLayer drawableLayer = _controller.getDrawableLayer(layerIndex);
      DrawableFeature? drawableFeature =
          _hoverFindDrawableFeature(drawableLayer, worldCoordinate);
      if (drawableFeature != null) {
        MapLayer layer = drawableLayer.layer;
        hoverHighlightRule = MapSingleHighlight(
            layerId: layer.id, drawableFeature: drawableFeature);
        break;
      }
    }

    if (_controller.highlight != hoverHighlightRule) {
      _updateHover(hoverHighlightRule);
    }
  }

  /// Finds the first feature that contains a coordinate.
  DrawableFeature? _hoverFindDrawableFeature(
      DrawableLayer drawableLayer, Offset worldCoordinate) {
    for (DrawableLayerChunk chunk in drawableLayer.chunks) {
      for (int index = 0; index < chunk.length; index++) {
        DrawableFeature drawableFeature = chunk.getDrawableFeature(index);
        MapFeature feature = drawableFeature.feature;
        if (widget.hoverRule != null && widget.hoverRule!(feature) == false) {
          continue;
        }
        Drawable? drawable = drawableFeature.drawable;
        if (drawable != null && drawable.contains(worldCoordinate)) {
          return drawableFeature;
        }
      }
    }
  }

  void _updateHover(MapSingleHighlight? hoverHighlightRule) {
    if (hoverHighlightRule != null) {
      _controller.setHighlight(hoverHighlightRule);
    } else {
      _controller.clearHighlight();
    }
    if (widget.hoverListener != null) {
      widget.hoverListener!(hoverHighlightRule?.drawableFeature?.feature);
    }
  }
}

/// The [VectorMap] layout.
class _VectorMapLayoutDelegate extends MultiChildLayoutDelegate {
  _VectorMapLayoutDelegate(this.count);

  final int count;

  @override
  void performLayout(Size size) {
    Size childSize = Size.zero;
    for (int id = 0; id < count; id++) {
      if (hasChild(id)) {
        if (id == 0) {
          childSize = layoutChild(id, BoxConstraints.tight(size));
          positionChild(id, Offset.zero);
        } else {
          childSize = layoutChild(id, BoxConstraints.loose(size));
          positionChild(
              id,
              Offset(size.width - childSize.width,
                  size.height - childSize.height));
        }
      }
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return false;
  }
}

typedef FeatureClickListener = Function(MapFeature feature);

typedef HoverRule = bool Function(MapFeature feature);

typedef HoverListener = Function(MapFeature? feature);
