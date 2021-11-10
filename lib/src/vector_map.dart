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
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/low_quality_mode.dart';
import 'package:vector_map/src/vector_map_controller.dart';
import 'package:vector_map/src/vector_map_api.dart';
import 'package:vector_map/src/map_highlight.dart';
import 'package:vector_map/src/map_painter.dart';

/// Vector map widget.
class VectorMap extends StatefulWidget {
  /// The default [contourThickness] value is 1.
  VectorMap(
      {Key? key,
      List<MapLayer>? layers,
      this.delayToRefreshResolution = 1000,
      this.color,
      this.borderColor = Colors.black54,
      this.borderThickness = 1,
      this.contourThickness = 1,
      this.layersPadding = const EdgeInsets.all(8),
      this.hoverRule,
      this.hoverListener,
      this.clickListener,
      this.debugger,
      this.addons,
      this.panAndZoomEnabled = true,
      this.lowQualityMode})
      : this.layers = layers != null ? layers : [],
        super(key: key) {
    for (int index = 0; index < this.layers.length; index++) {
      MapLayer layer = this.layers[index];
      if (_idAndIndexLayers.containsKey(layer.id)) {
        throw VectorMapError('Duplicate layer id: ' + layer.id.toString());
      }
      _idAndIndexLayers[layer.id] = index;
    }
  }

  final List<MapLayer> layers;
  final Map<int, int> _idAndIndexLayers = Map<int, int>();
  final double contourThickness;
  final int delayToRefreshResolution;
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

  bool get hoverDrawable {
    for (MapLayer layer in layers) {
      if (layer.hoverDrawable) {
        return true;
      }
    }
    return false;
  }
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
class _VectorMapState extends State<VectorMap> implements VectorMapApi {
  MapHighlight? _highlight;
  VectorMapController? _controller;
  Size? _canvasSize;
  bool _drawBuffers = false;
  bool _initialFit = true;
  _PanStart? _panStart;

  @override
  void initState() {
    super.initState();
    _controller = VectorMapController();
    _controller!.setDebugger(widget.debugger);
    _controller!.setLayers(widget.layers);
    _controller!.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller!.removeListener(_rebuild);
    _controller!.setDebugger(null);
    super.dispose();
  }

  void _rebuild() {
    setState(() {
      // rebuild
    });
  }

  @override
  int getLayerIndexById(int id) {
    int? index = widget._idAndIndexLayers[id];
    if (index == null) {
      throw VectorMapError('Invalid layer id: $id');
    }
    return index;
  }

  @override
  void clearHighlight() {
    setState(() {
      _highlight = null;
    });
  }

  @override
  void setHighlight(MapHighlight newHighlight) {
    setState(() {
      _highlight = newHighlight;
    });
  }

  bool get _onPan => _panStart != null;

  void _startUpdate({required Size canvasSize}) {
    if (mounted && canvasSize == _canvasSize) {
      _controller!.clearBuffers();
      _drawBuffers = true;
      // The size remains the same as when this method was scheduled
      _controller!.updateDrawableFeatures(
          canvasSize: canvasSize, contourThickness: widget.contourThickness);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (widget.layers.isNotEmpty) {
      Widget mapCanvas = _buildMapCanvas();
      if (widget.addons != null) {
        List<LayoutId> children = [LayoutId(id: 0, child: mapCanvas)];
        int count = 1;
        for (MapAddon addon in widget.addons!) {
          DrawableFeature? hover;
          if (_highlight != null && _highlight is MapSingleHighlight) {
            hover = (_highlight as MapSingleHighlight).drawableFeature;
          }
          children.add(LayoutId(
              id: count,
              child: addon.buildWidget(
                  context: context, mapApi: this, hover: hover?.feature)));
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

      if (_canvasSize != canvasSize) {
        _canvasSize = canvasSize;
        _drawBuffers = false;
        _controller!.cancelUpdate();
        if (_initialFit) {
          _controller!.fit(canvasSize);
          _initialFit = false;
        }
        if (_controller!.firstUpdate) {
          // first build without delay
          Future.microtask(() => _startUpdate(canvasSize: canvasSize));
        } else {
          // schedule the drawables build
          Future.delayed(
              Duration(milliseconds: widget.delayToRefreshResolution),
              () => _startUpdate(canvasSize: canvasSize));
        }
      }

      MapPainter mapPainter = MapPainter(
          controller: _controller!,
          highlight: _highlight,
          drawBuffers: _drawBuffers,
          contourThickness: widget.contourThickness);

      CustomPaint customPaint =
          CustomPaint(painter: mapPainter, child: Container());

      MouseRegion mouseRegion = MouseRegion(
        child: customPaint,
        onHover: (event) => _onHover(
            localPosition: event.localPosition,
            canvasToWorld: _controller!.canvasToWorld),
        onExit: (event) {
          if (_highlight != null) {
            _updateHover(null);
          }
          widget.debugger?.updateMouseHover();
        },
      );

      Widget mouseListener = mouseRegion;
      if (widget.panAndZoomEnabled) {
        mouseListener = Listener(
            child: mouseRegion,
            onPointerUp: (event) {
              setState(() {
                _panStart = null;
                // schedule the drawables build
                Future.delayed(
                    Duration.zero, () => _startUpdate(canvasSize: canvasSize));
              });
              _onHover(
                  localPosition: event.localPosition,
                  canvasToWorld: _controller!.canvasToWorld);
            },
            onPointerDown: (event) {
              _controller?.cancelUpdate();
              if (_highlight != null) {
                _updateHover(null);
              }
              if (_controller != null) {
                setState(() {
                  _panStart = _PanStart(
                      mouseLocation: event.localPosition,
                      translateX: _controller!.translateX,
                      translateY: _controller!.translateY);
                  _drawBuffers = false;
                });
              }
            },
            onPointerMove: (event) {
              if (_panStart != null) {
                double diffX =
                    _panStart!.mouseLocation.dx - event.localPosition.dx;
                double diffY =
                    _panStart!.mouseLocation.dy - event.localPosition.dy;
                _controller?.setTranslate(_panStart!.translateX - diffX,
                    _panStart!.translateY - diffY);
              }
            },
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _drawBuffers = false;
                bool zoomIn = event.scrollDelta.dy < 0;
                _controller?.zoom(canvasSize, event.localPosition, zoomIn);
                //TODO cada zoom anula anterior?
                // schedule the drawables build
                Future.delayed(
                    Duration.zero, () => _startUpdate(canvasSize: canvasSize));
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
    if (_highlight != null &&
        _highlight is MapSingleHighlight &&
        widget.clickListener != null) {
      MapSingleHighlight singleHighlight = _highlight as MapSingleHighlight;
      if (singleHighlight.drawableFeature != null) {
        widget.clickListener!(singleHighlight.drawableFeature!.feature);
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
    for (int layerIndex = _controller!.drawableLayersLength - 1;
        layerIndex >= 0;
        layerIndex--) {
      DrawableLayer drawableLayer = _controller!.getDrawableLayer(layerIndex);
      DrawableFeature? drawableFeature =
          _hoverFindDrawableFeature(drawableLayer, worldCoordinate);
      if (drawableFeature != null) {
        hoverHighlightRule = MapSingleHighlight(layerIndex, drawableFeature);
        break;
      }
    }

    if (_highlight != hoverHighlightRule) {
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
    if (widget.hoverDrawable) {
      // repaint
      setState(() {
        _highlight = hoverHighlightRule;
      });
    } else {
      _highlight = hoverHighlightRule;
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
