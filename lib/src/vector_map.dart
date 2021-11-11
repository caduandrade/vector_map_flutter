import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/addon/map_addon.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/debugger.dart';
import 'package:vector_map/src/drawable/drawable.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/drawable/drawable_layer_chunk.dart';
import 'package:vector_map/src/low_quality_mode.dart';
import 'package:vector_map/src/vector_map_controller.dart';
import 'package:vector_map/src/map_highlight.dart';
import 'package:vector_map/src/map_painter.dart';

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
      this.debugger,
      this.addons,
      this.panAndZoomEnabled = true,
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
  final MapDebugger? debugger;
  final List<MapAddon>? addons;
  final LowQualityMode? lowQualityMode;
  final bool panAndZoomEnabled;

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
  bool _drawBuffers = false;
  _PanStart? _panStart;
  int _currentUpdateTicket = 0;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    }
    _controller.setDebugger(widget.debugger);
    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant VectorMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        widget.controller != oldWidget.controller) {
      _controller.removeListener(_rebuild);
      _controller.setDebugger(null);
      _controller = widget.controller!;
      _controller.setDebugger(widget.debugger);
      _controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _controller.setDebugger(null);
    super.dispose();
  }

  void _rebuild() {
    setState(() {
      // rebuild
    });
  }

  bool get _onPan => _panStart != null;

  void _startUpdate({required int ticket}) {
    if (mounted && _currentUpdateTicket == ticket) {
      // The size remains the same as when this method was scheduled
      _controller.updateDrawableFeatures();
      _drawBuffers = true;
    }
  }

  void _updateTicket() {
    _currentUpdateTicket++;
    if (_currentUpdateTicket == 999999) {
      _currentUpdateTicket = 0;
    }
  }

  void _scheduleUpdate({required bool delayed}) {
    if (delayed) {
      _updateTicket();
      int ticket = _currentUpdateTicket;
      Future.delayed(
          Duration(milliseconds: _controller.delayToRefreshResolution),
          () => _startUpdate(ticket: ticket));
    } else {
      Future.microtask(() => _startUpdate(ticket: _currentUpdateTicket));
    }
  }



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

      if (_controller.lastCanvasSize != canvasSize) {
        _controller.setLastCanvasSize(canvasSize);
        _drawBuffers = false;
        _controller.cancelUpdate();
        if (_controller.firstUpdate) {
          // first build without delay
          _scheduleUpdate(delayed: false);
        } else {
          // schedule the drawables build
          _scheduleUpdate(delayed: true);
        }
      }

      MapPainter mapPainter =
          MapPainter(controller: _controller, drawBuffers: _drawBuffers);

      CustomPaint customPaint =
          CustomPaint(painter: mapPainter, child: Container());

      MouseRegion mouseRegion = MouseRegion(
        child: customPaint,
        onHover: (event) => _onHover(
            localPosition: event.localPosition,
            canvasToWorld: _controller.canvasToWorld),
        onExit: (event) {
          if (_controller.highlight != null) {
            _updateHover(null);
          }
          widget.debugger?.updateMouseHover();
        },
      );

      Widget mouseListener = mouseRegion;
      if (widget.panAndZoomEnabled) {
        mouseListener = Listener(
            child: mouseRegion,
            onPointerDown: (event) {
              // cancel running update
              _controller.cancelUpdate();
              // cancel scheduled update
              _updateTicket();
              if (_controller.highlight != null) {
                _updateHover(null);
              }
              setState(() {
                _panStart = _PanStart(
                    mouseLocation: event.localPosition,
                    translateX: _controller.translateX,
                    translateY: _controller.translateY);
                _drawBuffers = false;
              });
            },
            onPointerMove: (event) {
              if (_panStart != null) {
                _drawBuffers = false;
                double diffX =
                    _panStart!.mouseLocation.dx - event.localPosition.dx;
                double diffY =
                    _panStart!.mouseLocation.dy - event.localPosition.dy;
                _controller.translate(_panStart!.translateX - diffX,
                    _panStart!.translateY - diffY);
              }
            },
            onPointerUp: (event) {
              setState(() {
                _panStart = null;
                // schedule the drawables build
                _scheduleUpdate(delayed: true);
              });
              _onHover(
                  localPosition: event.localPosition,
                  canvasToWorld: _controller.canvasToWorld);
            },
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _drawBuffers = false;
                _controller.cancelUpdate();
                bool zoomIn = event.scrollDelta.dy < 0;
                _controller.zoom(event.localPosition, zoomIn);
                // schedule the drawables build
                _scheduleUpdate(delayed: true);
              }
            });
      }

      return ClipRect(
          child:
              GestureDetector(child: mouseListener, onTap: () => _onClick()));
    });

    return Container(child: layoutBuilder, padding: widget.layersPadding);
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

    widget.debugger?.updateMouseHover(
        canvasLocation: localPosition, worldCoordinate: worldCoordinate);

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
