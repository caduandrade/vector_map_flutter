import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/debugger.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/layer.dart';
import 'package:vector_map/src/map_resolution.dart';
import 'package:vector_map/src/matrix.dart';
import 'package:vector_map/src/paintable.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme.dart';

/// Vector map widget.
class VectorMap extends StatefulWidget {
  /// The default [contourThickness] value is 1.
  VectorMap(
      {Key? key,
      List<MapLayer>? layers,
      this.delayToRefreshResolution = 1000,
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

  bool get hoverPaintable {
    for (MapLayer layer in layers) {
      if (layer.hoverPaintable) {
        return true;
      }
    }
    return false;
  }
}

typedef FeatureClickListener = Function(MapFeature feature);

typedef HoverRule = bool Function(MapFeature feature);

typedef HoverListener = Function(MapFeature? feature);

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
          onFinish: _onFinish);
      _mapResolutionBuilder!.start();
    }
  }

  _onFinish(MapResolution newMapResolution) {
    if (mounted) {
      setState(() {
        _mapResolution = newMapResolution;
        _mapResolutionBuilder = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Decoration? decoration;
    if (widget.borderColor != null &&
        widget.borderThickness != null &&
        widget.borderThickness! > 0) {
      decoration = BoxDecoration(
          border: Border.all(
              color: widget.borderColor!, width: widget.borderThickness!));
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
            geometryBounds: widget.layersBounds!);

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

        if (widget.hoverPaintable ||
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

  _onHover(PointerHoverEvent event, CanvasMatrix canvasMatrix) {
    if (_mapResolution != null) {
      Offset o = MatrixUtils.transformPoint(
          canvasMatrix.screenToGeometry, event.localPosition);

      bool found = false;
      if (widget.layers.isNotEmpty) {
        for (int layerIndex = widget.layers.length - 1;
            found == false && layerIndex >= 0;
            layerIndex--) {
          MapLayer layer = widget.layers[layerIndex];
          for (MapFeature feature in layer.dataSource.features.values) {
            if (widget.hoverRule != null &&
                widget.hoverRule!(feature) == false) {
              continue;
            }

            PaintableLayer paintableLayer =
                _mapResolution!.paintableLayers[layerIndex];
            if (paintableLayer.paintableFeatures.containsKey(feature.id) ==
                false) {
              throw VectorMapError(
                  'No paintable geometry for id: ' + feature.id.toString());
            }
            PaintableFeature paintableFeature =
                paintableLayer.paintableFeatures[feature.id]!;
            found = paintableFeature.contains(o);
            if (found) {
              if (_hover == null ||
                  _hover!.layerIndex != layerIndex ||
                  _hover!.feature != feature) {
                _updateHover(_HoverFeature(layerIndex, feature));
              }
              break;
            }
          }
        }
      }
      if (found == false && _hover != null) {
        _updateHover(null);
      }
    }
  }

  _updateHover(_HoverFeature? newHover) {
    if (widget.hoverPaintable) {
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
        layerIndex < mapResolution.paintableLayers.length;
        layerIndex++) {
      PaintableLayer paintableLayer = mapResolution.paintableLayers[layerIndex];

      if (canvasMatrix.widgetSize == mapResolution.widgetSize) {
        canvas.drawImage(
            mapResolution.layerBuffers[layerIndex], Offset.zero, Paint());
      } else {
        canvas.save();
        canvasMatrix.applyOn(canvas);
        paintableLayer.drawContourOn(
            canvas: canvas,
            contourThickness: contourThickness,
            scale: canvasMatrix.scale,
            antiAlias: false);
        canvas.restore();
      }

      // drawing the hover
      if (hover != null && hover!.layerIndex == layerIndex) {
        MapLayer layer = paintableLayer.layer;
        if (layer.hoverTheme != null) {
          MapFeature feature = hover!.feature;
          MapTheme hoverTheme = layer.hoverTheme!;
          Color? hoverColor = hoverTheme.getColor(layer.dataSource, feature);
          if (hoverColor != null || hoverTheme.contourColor != null) {
            canvas.save();

            canvasMatrix.applyOn(canvas);

            int featureId = feature.id;
            if (paintableLayer.paintableFeatures.containsKey(featureId) ==
                false) {
              throw VectorMapError('No path for id: $featureId');
            }

            PaintableFeature paintableFeature =
                paintableLayer.paintableFeatures[featureId]!;
            if (hoverColor != null) {
              var paint = Paint()
                ..style = PaintingStyle.fill
                ..color = hoverColor
                ..isAntiAlias = true;
              paintableFeature.drawOn(canvas, paint);
            }

            if (contourThickness > 0) {
              _drawHoverContour(canvas, paintableLayer.layer, hoverTheme,
                  paintableFeature, canvasMatrix);
            }

            canvas.restore();
          }
        }
      }
    }

    // drawing the overlay hover
    if (contourThickness > 0 && overlayHoverContour && hover != null) {
      PaintableLayer paintableLayer =
          mapResolution.paintableLayers[hover!.layerIndex];
      MapLayer layer = paintableLayer.layer;
      if (layer.hoverTheme != null) {
        canvas.save();

        canvasMatrix.applyOn(canvas);

        MapTheme hoverTheme = layer.hoverTheme!;
        PaintableFeature paintableFeature =
            paintableLayer.paintableFeatures[hover!.feature.id]!;
        _drawHoverContour(canvas, paintableLayer.layer, hoverTheme,
            paintableFeature, canvasMatrix);

        canvas.restore();
      }
    }

    // drawing labels
    for (int layerIndex = 0;
        layerIndex < mapResolution.paintableLayers.length;
        layerIndex++) {
      PaintableLayer paintableLayer = mapResolution.paintableLayers[layerIndex];
      MapLayer layer = paintableLayer.layer;
      MapDataSource dataSource = layer.dataSource;
      MapTheme theme = layer.theme;
      MapTheme? hoverTheme = layer.hoverTheme;
      if (theme.labelVisibility != null ||
          (hoverTheme != null && hoverTheme.labelVisibility != null)) {
        for (MapFeature feature in dataSource.features.values) {
          if (feature.label != null) {
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
      PaintableFeature paintableFeature, CanvasMatrix canvasMatrix) {
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
    paintableFeature.drawOn(canvas, paint);
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

    PaintableLayer paintableLayer = mapResolution.paintableLayers[layerIndex];
    PaintableFeature paintableFeature =
        paintableLayer.paintableFeatures[feature.id]!;
    Rect bounds = MatrixUtils.transformRect(
        canvasMatrix.geometryToScreen, paintableFeature.getBounds());
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
}
