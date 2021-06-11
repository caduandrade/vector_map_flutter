import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/debugger.dart';
import 'package:vector_map/src/drawable/drawable_feature.dart';
import 'package:vector_map/src/drawable/drawable_layer.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/layer.dart';
import 'package:vector_map/src/map_resolution.dart';
import 'package:vector_map/src/matrix.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme/theme.dart';
import 'package:vector_map/src/typedefs.dart';

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
      this.padding = 8,
      this.hoverRule,
      this.hoverListener,
      this.clickListener,
      this.overlayHoverContour = false,
      this.debugger})
      : this.layers = layers != null ? layers : [],
        this.layersBounds = layers != null ? MapLayer.boundsOf(layers) : null,
        super(key: key) {
    debugger?.initialize(this.layers);
  }

  final List<MapLayer> layers;
  final Rect? layersBounds;
  final double contourThickness;
  final int delayToRefreshResolution;
  final Color? color;
  final Color? borderColor;
  final double? borderThickness;
  final double? padding;
  final HoverRule? hoverRule;
  final HoverListener? hoverListener;
  final FeatureClickListener? clickListener;
  final bool overlayHoverContour;
  final MapDebugger? debugger;

  @override
  State<StatefulWidget> createState() => VectorMapState();

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
class VectorMapState extends State<VectorMap> {
  _HoverFeature? _hover;

  Size? _lastBuildSize;
  MapResolution? _mapResolution;
  MapResolutionBuilder? _mapResolutionBuilder;

  _updateMapResolution(CanvasMatrix canvasMatrix) {
    if (mounted && _lastBuildSize == canvasMatrix.widgetSize) {
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

  _onFinish(MapResolution newMapResolution) {
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
    EdgeInsetsGeometry? padding;
    if (widget.padding != null && widget.padding! > 0) {
      padding = EdgeInsets.all(widget.padding!);
    }

    Widget? content;
    if (widget.layers.isNotEmpty) {
      content = LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        CanvasMatrix canvasMatrix = CanvasMatrix(
            widgetWidth: constraints.maxWidth,
            widgetHeight: constraints.maxHeight,
            worldBounds: widget.layersBounds!);

        if (_lastBuildSize != canvasMatrix.widgetSize) {
          _lastBuildSize = canvasMatrix.widgetSize;
          if (_mapResolution == null) {
            if (_mapResolutionBuilder == null) {
              // first build without delay
              Future.microtask(() => _updateMapResolution(canvasMatrix));
            }
            return Center(
              child: Text('updating...'),
            );
          } else {
            // updating map resolution
            Future.delayed(
                Duration(milliseconds: widget.delayToRefreshResolution), () {
              _updateMapResolution(canvasMatrix);
            });
          }
        }

        _MapPainter mapPainter = _MapPainter(
            mapResolution: _mapResolution!,
            hover: _hover,
            canvasMatrix: canvasMatrix,
            contourThickness: widget.contourThickness,
            overlayHoverContour: widget.overlayHoverContour);

        Widget map = CustomPaint(painter: mapPainter, child: Container());

        if (widget.hoverDrawable ||
            widget.hoverListener != null ||
            widget.clickListener != null) {
          map = MouseRegion(
            child: map,
            onHover: (event) => _onHover(event, canvasMatrix),
            onExit: (event) {
              if (_hover != null) {
                _updateHover(null);
              }
            },
          );
        }
        if (widget.clickListener != null) {
          map = GestureDetector(child: map, onTap: () => _onClick());
        }
        return ClipRect(child: map);
      });
    }
    // empty container without map
    return Container(child: content, decoration: decoration, padding: padding);
  }

  _onClick() {
    if (_hover != null && widget.clickListener != null) {
      widget.clickListener!(_hover!.feature);
    }
  }

  /// Triggered when a pointer moves over the map.
  _onHover(PointerHoverEvent event, CanvasMatrix canvasMatrix) {
    if (_mapResolution != null) {
      Offset worldCoordinate = MatrixUtils.transformPoint(
          canvasMatrix.screenToWorld, event.localPosition);

      _HoverFeature? hoverFeature;
      for (int layerIndex = _mapResolution!.drawableLayers.length - 1;
          layerIndex >= 0;
          layerIndex--) {
        DrawableLayer drawableLayer =
            _mapResolution!.drawableLayers[layerIndex];
        MapFeature? feature =
            drawableLayer.featureContains(widget.hoverRule, worldCoordinate);
        if (feature != null) {
          hoverFeature = _HoverFeature(layerIndex, feature);
          break;
        }
      }

      if (_hover != hoverFeature) {
        _updateHover(hoverFeature);
      }
    }
  }

  _updateHover(_HoverFeature? newHover) {
    if (widget.hoverDrawable) {
      // repaint
      setState(() {
        _hover = newHover;
      });
    } else {
      _hover = newHover;
    }
    if (widget.hoverListener != null) {
      widget.hoverListener!(newHover?.feature);
    }
  }
}

/// Painter for [VectorMap].
class _MapPainter extends CustomPainter {
  _MapPainter(
      {required this.mapResolution,
      required this.canvasMatrix,
      required this.contourThickness,
      required this.overlayHoverContour,
      this.hover});

  final CanvasMatrix canvasMatrix;
  final double contourThickness;
  final _HoverFeature? hover;
  final MapResolution mapResolution;
  final bool overlayHoverContour;

  @override
  void paint(Canvas canvas, Size size) {
    // drawing layers
    for (int layerIndex = 0;
        layerIndex < mapResolution.drawableLayers.length;
        layerIndex++) {
      DrawableLayer drawableLayer = mapResolution.drawableLayers[layerIndex];

      if (canvasMatrix.widgetSize == mapResolution.widgetSize) {
        canvas.drawImage(
            mapResolution.layerBuffers[layerIndex], Offset.zero, Paint());
      } else {
        canvas.save();
        canvasMatrix.applyOn(canvas);
        drawableLayer.drawContourOn(
            canvas: canvas,
            contourThickness: contourThickness,
            scale: canvasMatrix.scale,
            antiAlias: false);
        canvas.restore();
      }

      // drawing the hover
      if (hover != null && hover!.layerIndex == layerIndex) {
        MapFeature feature = hover!.feature;
        int featureId = feature.id;
        if (drawableLayer.drawableFeatures.containsKey(featureId) == false) {
          throw VectorMapError('No path for id: $featureId');
        }

        DrawableFeature drawableFeature =
            drawableLayer.drawableFeatures[featureId]!;

        MapLayer layer = drawableLayer.layer;
        if (drawableFeature.visible &&
            layer.hoverTheme != null &&
            drawableFeature.hasFill) {
          MapTheme hoverTheme = layer.hoverTheme!;
          Color? hoverColor = hoverTheme.getColor(layer.dataSource, feature);
          if (hoverColor != null || hoverTheme.contourColor != null) {
            canvas.save();

            canvasMatrix.applyOn(canvas);

            if (hoverColor != null) {
              var paint = Paint()
                ..style = PaintingStyle.fill
                ..color = hoverColor
                ..isAntiAlias = true;
              drawableFeature.drawOn(canvas, paint, canvasMatrix.scale);
            }

            if (contourThickness > 0) {
              _drawHoverContour(canvas, drawableLayer.layer, hoverTheme,
                  drawableFeature, canvasMatrix);
            }

            canvas.restore();
          }
        }
      }
    }

    // drawing the overlay hover
    if (contourThickness > 0 && overlayHoverContour && hover != null) {
      DrawableLayer drawableLayer =
          mapResolution.drawableLayers[hover!.layerIndex];
      DrawableFeature drawableFeature =
          drawableLayer.drawableFeatures[hover!.feature.id]!;
      MapLayer layer = drawableLayer.layer;
      if (drawableFeature.visible && layer.hoverTheme != null) {
        canvas.save();
        canvasMatrix.applyOn(canvas);
        MapTheme hoverTheme = layer.hoverTheme!;
        _drawHoverContour(canvas, drawableLayer.layer, hoverTheme,
            drawableFeature, canvasMatrix);
        canvas.restore();
      }
    }

    // drawing labels
    for (int layerIndex = 0;
        layerIndex < mapResolution.drawableLayers.length;
        layerIndex++) {
      DrawableLayer drawableLayer = mapResolution.drawableLayers[layerIndex];
      MapLayer layer = drawableLayer.layer;
      MapDataSource dataSource = layer.dataSource;
      MapTheme theme = layer.theme;
      MapTheme? hoverTheme = layer.hoverTheme;
      if (theme.labelVisibility != null ||
          (hoverTheme != null && hoverTheme.labelVisibility != null)) {
        for (MapFeature feature in dataSource.features.values) {
          DrawableFeature drawableFeature =
              drawableLayer.drawableFeatures[feature.id]!;
          if (drawableFeature.visible && feature.label != null) {
            LabelVisibility? labelVisibility;
            if (hover != null &&
                layerIndex == hover!.layerIndex &&
                hover!.feature == feature &&
                hoverTheme != null &&
                hoverTheme.labelVisibility != null) {
              labelVisibility = hoverTheme.labelVisibility;
            } else {
              labelVisibility = theme.labelVisibility;
            }

            if (labelVisibility != null && labelVisibility(feature)) {
              Color? featureColor;
              LabelStyleBuilder? labelStyleBuilder;

              if (hover != null &&
                  layerIndex == hover!.layerIndex &&
                  hover!.feature == feature &&
                  hoverTheme != null) {
                featureColor = hoverTheme.getColor(dataSource, feature);
                labelStyleBuilder = hoverTheme.labelStyleBuilder;
              }

              if (featureColor == null) {
                featureColor =
                    MapTheme.getThemeOrDefaultColor(dataSource, feature, theme);
              }
              if (labelStyleBuilder == null) {
                labelStyleBuilder = theme.labelStyleBuilder;
              }

              _drawLabel(
                  canvas, layerIndex, feature, featureColor, labelStyleBuilder);
            }
          }
        }
      }
    }
  }

  _drawHoverContour(Canvas canvas, MapLayer layer, MapTheme hoverTheme,
      DrawableFeature drawableFeature, CanvasMatrix canvasMatrix) {
    Color contourColor = MapTheme.defaultContourColor;
    if (hoverTheme.contourColor != null) {
      contourColor = hoverTheme.contourColor!;
    } else if (layer.theme.contourColor != null) {
      contourColor = layer.theme.contourColor!;
    }

    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = contourColor
      ..strokeWidth = contourThickness / canvasMatrix.scale
      ..isAntiAlias = true;
    drawableFeature.drawOn(canvas, paint, canvasMatrix.scale);
  }

  _drawLabel(Canvas canvas, int layerIndex, MapFeature feature,
      Color featureColor, LabelStyleBuilder? labelStyleBuilder) {
    Color labelColor = _labelColorFrom(featureColor);

    TextStyle? labelStyle;
    if (labelStyleBuilder != null) {
      labelStyle = labelStyleBuilder(feature, featureColor, labelColor);
    }
    if (labelStyle == null) {
      labelStyle = TextStyle(
        color: labelColor,
        fontSize: 11,
      );
    }

    DrawableLayer drawableLayer = mapResolution.drawableLayers[layerIndex];
    DrawableFeature drawableFeature =
        drawableLayer.drawableFeatures[feature.id]!;
    Rect bounds = MatrixUtils.transformRect(
        canvasMatrix.worldToScreen, drawableFeature.getBounds());
    _drawText(canvas, bounds.center, feature.label!, labelStyle);
  }

  Color _labelColorFrom(Color featureColor) {
    final luminance = featureColor.computeLuminance();
    if (luminance > 0.55) {
      return const Color(0xFF000000);
    }
    return const Color(0xFFFFFFFF);
  }

  void _drawText(
      Canvas canvas, Offset center, String text, TextStyle textStyle) {
    TextSpan textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: 0,
    );

    double xCenter = center.dx - (textPainter.width / 2);
    double yCenter = center.dy - (textPainter.height / 2);
    textPainter.paint(canvas, Offset(xCenter, yCenter));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _HoverFeature {
  _HoverFeature(this.layerIndex, this.feature);

  final MapFeature feature;
  final int layerIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HoverFeature &&
          runtimeType == other.runtimeType &&
          feature == other.feature &&
          layerIndex == other.layerIndex;

  @override
  int get hashCode => feature.hashCode ^ layerIndex.hashCode;
}
