import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/addon/map_addon.dart';
import 'package:vector_map/src/data/map_feature.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/debugger.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/low_quality_mode.dart';
import 'package:vector_map/src/vector_map_api.dart';
import 'package:vector_map/src/map_highlight.dart';
import 'package:vector_map/src/map_painter.dart';
import 'package:vector_map/src/map_resolution.dart';
import 'package:vector_map/src/matrix.dart';
import 'package:vector_map/src/simplifier.dart';

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
      this.lowQualityMode})
      : this.layers = layers != null ? layers : [],
        super(key: key) {
    debugger?.initialize(this.layers);
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

  @override
  State<StatefulWidget> createState() {
    return _VectorMapState(worldBounds: MapLayer.boundsOf(layers));
  }

  bool get hoverDrawable {
    for (MapLayer layer in layers) {
      if (layer.hoverDrawable) {
        return true;
      }
    }
    return false;
  }
}

/// [VectorMap] state.
class _VectorMapState extends State<VectorMap> implements VectorMapApi {
  CanvasMatrix _canvasMatrix;
  MapHighlight? _highlight;
  Size? _lastBuildSize;
  MapResolution? _mapResolution;
  MapResolutionBuilder? _mapResolutionBuilder;

  _VectorMapState({required Rect? worldBounds})
      : this._canvasMatrix = CanvasMatrix(worldBounds: worldBounds);

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

  void _updateMapResolution(CanvasMatrix canvasMatrix) {
    if (mounted && _lastBuildSize == canvasMatrix.canvasSize) {
      if (_mapResolutionBuilder != null) {
        _mapResolutionBuilder!.stop();
      }
      _mapResolutionBuilder = MapResolutionBuilder(
          layers: widget.layers,
          contourThickness: widget.contourThickness,
          canvasMatrix: canvasMatrix,
          simplifier: IntegerSimplifier(),
          onFinish: _onFinish,
          debugger: widget.debugger);
      _mapResolutionBuilder!.start();
    }
  }

  void _onFinish(MapResolution newMapResolution) {
    if (mounted) {
      setState(() {
        _mapResolution = newMapResolution;
        _mapResolutionBuilder = null;
      });
      widget.debugger?.updateMapResolution(newMapResolution);
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
          MapFeature? hover;
          if (_highlight != null && _highlight is MapSingleHighlight) {
            hover = (_highlight as MapSingleHighlight).feature;
          }
          children.add(LayoutId(
              id: count,
              child: addon.buildWidget(
                  context: context, mapApi: this, hover: hover)));
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

      _canvasMatrix.canvasSize =
          Size(constraints.maxWidth, constraints.maxHeight);

      _canvasMatrix.fit();

      if (_lastBuildSize != _canvasMatrix.canvasSize) {
        _lastBuildSize = _canvasMatrix.canvasSize;
        if (_mapResolution == null) {
          if (_mapResolutionBuilder == null) {
            // first build without delay
            Future.microtask(() => _updateMapResolution(_canvasMatrix));
          }
          return Center(
            child: Text('Updating...'),
          );
        } else {
          // updating map resolution
          Future.delayed(
              Duration(milliseconds: widget.delayToRefreshResolution), () {
            _updateMapResolution(_canvasMatrix);
          });
        }
      }

      MapPainter mapPainter = MapPainter(
          mapResolution: _mapResolution!,
          highlight: _highlight,
          canvasMatrix: _canvasMatrix,
          contourThickness: widget.contourThickness);

      CustomPaint customPaint =
          CustomPaint(painter: mapPainter, child: Container());

      MouseRegion mouseRegion = MouseRegion(
        child: customPaint,
        onHover: (event) => _onHover(event, _canvasMatrix),
        onExit: (event) {
          if (_highlight != null) {
            _updateHover(null);
          }
          widget.debugger?.updateMouseHover();
        },
      );

      return ClipRect(
          child: GestureDetector(child: mouseRegion, onTap: () => _onClick()));
    });

    return Container(child: layoutBuilder, padding: widget.layersPadding);
  }

  void _onClick() {
    if (_highlight != null &&
        _highlight is MapSingleHighlight &&
        widget.clickListener != null) {
      widget.clickListener!((_highlight as MapSingleHighlight).feature);
    }
  }

  /// Triggered when a pointer moves over the map.
  void _onHover(PointerHoverEvent event, CanvasMatrix canvasMatrix) {
    if (_mapResolution != null) {
      Offset worldCoordinate = MatrixUtils.transformPoint(
          canvasMatrix.screenToWorld, event.localPosition);

      widget.debugger?.updateMouseHover(
          canvasLocation: event.localPosition,
          worldCoordinate: worldCoordinate);

      MapSingleHighlight? hoverHighlightRule;
      for (int layerIndex = _mapResolution!.drawableLayers.length - 1;
          layerIndex >= 0;
          layerIndex--) {
        DrawableLayer drawableLayer =
            _mapResolution!.drawableLayers[layerIndex];
        MapFeature? feature = _hoverFindFeature(drawableLayer, worldCoordinate);
        if (feature != null) {
          hoverHighlightRule = MapSingleHighlight(layerIndex, feature);
          break;
        }
      }

      if (_highlight != hoverHighlightRule) {
        _updateHover(hoverHighlightRule);
      }
    }
  }

  /// Finds the first feature that contains a coordinate.
  MapFeature? _hoverFindFeature(
      DrawableLayer drawableLayer, Offset worldCoordinate) {
    MapLayer layer = drawableLayer.layer;
    for (MapFeature feature in layer.dataSource.features.values) {
      if (widget.hoverRule != null && widget.hoverRule!(feature) == false) {
        continue;
      }

      if (drawableLayer.drawableFeatures.containsKey(feature.id) == false) {
        throw VectorMapError(
            'No drawable geometry for id: ' + feature.id.toString());
      }
      DrawableFeature drawableFeature =
          drawableLayer.drawableFeatures[feature.id]!;
      if (drawableFeature.contains(worldCoordinate)) {
        return feature;
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
      widget.hoverListener!(hoverHighlightRule?.feature);
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
