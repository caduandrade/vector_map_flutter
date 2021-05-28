import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/layer.dart';
import 'package:vector_map/src/map_resolution.dart';
import 'package:vector_map/src/matrices.dart';
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
      this.overlayHoverContour = false})
      : this.layers = layers != null ? layers : [],
        this.layersBounds = layers != null ? MapLayer.boundsOf(layers) : null,
        super(key: key);

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

  MapResolution? _mapResolution;

  Size? _lastBuildSize;
  MapResolutionBuilder? _mapResolutionBuilder;

  _updateMapResolution(MapMatrices mapMatrices, Size size) {
    if (mounted && _lastBuildSize == size) {
      if (_mapResolutionBuilder != null) {
        _mapResolutionBuilder!.stop();
      }
      _mapResolutionBuilder = MapResolutionBuilder(
          layers: widget.layers,
          contourThickness: widget.contourThickness,
          mapMatrices: mapMatrices,
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
        int? bufferWidth;
        int? bufferHeight;
        if (_mapResolution != null) {
          bufferWidth = _mapResolution!.bufferWidth;
          bufferHeight = _mapResolution!.bufferHeight;
        }
        MapMatrices mapMatrices = MapMatrices(
            widgetWidth: constraints.maxWidth,
            widgetHeight: constraints.maxHeight,
            geometryBounds: widget.layersBounds!,
            bufferWidth: bufferWidth,
            bufferHeight: bufferHeight);

        final Size size = Size(constraints.maxWidth, constraints.maxHeight);

        if (_lastBuildSize != size) {
          _lastBuildSize = size;
          if (_mapResolution == null) {
            if (_mapResolutionBuilder == null) {
              // first build without delay
              Future.microtask(() => _updateMapResolution(mapMatrices, size));
            }
            return Center(
              child: Text('updating...'),
            );
          } else {
            // updating map resolution
            Future.delayed(
                Duration(milliseconds: widget.delayToRefreshResolution), () {
              _updateMapResolution(mapMatrices, size);
            });
          }
        }

        _MapPainter mapPainter = _MapPainter(
            mapResolution: _mapResolution!,
            hover: _hover,
            mapMatrices: mapMatrices,
            contourThickness: widget.contourThickness,
            overlayHoverContour: widget.overlayHoverContour);

        Widget map = CustomPaint(painter: mapPainter, child: Container());

        if (widget.hoverPaintable ||
            widget.hoverListener != null ||
            widget.clickListener != null) {
          map = MouseRegion(
            child: map,
            onHover: (event) => _onHover(event, mapMatrices),
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

  _onHover(PointerHoverEvent event, MapMatrices mapMatrices) {
    if (_mapResolution != null) {
      Offset o = MatrixUtils.transformPoint(
          mapMatrices.canvasMatrix.screenToGeometry, event.localPosition);

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
            if (paintableLayer.paintableGeometries.containsKey(feature.id) ==
                false) {
              throw VectorMapError(
                  'No paintable geometry for id: ' + feature.id.toString());
            }
            PaintableGeometry paintableGeometry =
                paintableLayer.paintableGeometries[feature.id]!;
            found = paintableGeometry.contains(o);
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
      required this.mapMatrices,
      required this.contourThickness,
      required this.overlayHoverContour,
      this.hover});

  final MapMatrices mapMatrices;
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

      // drawing the buffer
      canvas.save();
      BufferPaintMatrix matrix = mapMatrices.bufferPaintMatrix!;
      canvas.translate(matrix.translateX, matrix.translateY);
      canvas.scale(matrix.scale);
      canvas.drawImage(paintableLayer.layerBuffer, Offset.zero, Paint());
      canvas.restore();

      // drawing the hover
      if (hover != null && hover!.layerIndex == layerIndex) {
        MapLayer layer = paintableLayer.layer;
        if (layer.hoverTheme != null) {
          MapFeature feature = hover!.feature;
          MapTheme hoverTheme = layer.hoverTheme!;
          Color? hoverColor = hoverTheme.getColor(layer.dataSource, feature);
          if (hoverColor != null || hoverTheme.contourColor != null) {
            canvas.save();

            CanvasMatrix canvasMatrix = mapMatrices.canvasMatrix;
            canvasMatrix.applyOn(canvas);

            int featureId = feature.id;
            if (paintableLayer.paintableGeometries.containsKey(featureId) ==
                false) {
              throw VectorMapError('No path for id: $featureId');
            }

            PaintableGeometry paintableGeometry =
                paintableLayer.paintableGeometries[featureId]!;
            if (hoverColor != null) {
              var paint = Paint()
                ..style = PaintingStyle.fill
                ..color = hoverColor
                ..isAntiAlias = true;
              paintableGeometry.draw(canvas, paint);
            }

            if (contourThickness > 0) {
              _drawHoverContour(canvas, paintableLayer.layer, hoverTheme,
                  paintableGeometry, canvasMatrix);
            }

            canvas.restore();
          }
        }
      }
    }

    if (contourThickness > 0 && overlayHoverContour && hover != null) {
      PaintableLayer paintableLayer =
          mapResolution.paintableLayers[hover!.layerIndex];
      MapLayer layer = paintableLayer.layer;
      if (layer.hoverTheme != null) {
        canvas.save();

        CanvasMatrix canvasMatrix = mapMatrices.canvasMatrix;
        canvasMatrix.applyOn(canvas);

        MapTheme hoverTheme = layer.hoverTheme!;
        PaintableGeometry paintableGeometry =
            paintableLayer.paintableGeometries[hover!.feature.id]!;
        _drawHoverContour(canvas, paintableLayer.layer, hoverTheme,
            paintableGeometry, canvasMatrix);

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
      PaintableGeometry paintableGeometry, CanvasMatrix canvasMatrix) {
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
    paintableGeometry.draw(canvas, paint);
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
    PaintableGeometry paintableGeometry =
        paintableLayer.paintableGeometries[feature.id]!;
    Rect bounds = MatrixUtils.transformRect(
        mapMatrices.canvasMatrix.geometryToScreen,
        paintableGeometry.getBounds());
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
