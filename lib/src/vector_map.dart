import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map/src/data_source.dart';
import 'package:vector_map/src/error.dart';
import 'package:vector_map/src/map_resolution.dart';
import 'package:vector_map/src/matrices.dart';
import 'package:vector_map/src/simplifier.dart';
import 'package:vector_map/src/theme.dart';

/// Vector map widget.
class VectorMap extends StatefulWidget {
  /// The default [contourThickness] value is 1.
  VectorMap(
      {Key? key,
      this.dataSource,
      this.delayToRefreshResolution = 1000,
      VectorMapTheme? theme,
      this.hoverTheme,
      this.borderColor = Colors.black54,
      this.borderThickness = 1,
      this.contourThickness = 1,
      this.padding = 8,
      this.hoverRule,
      this.hoverListener,
      this.clickListener})
      : this.theme = theme != null ? theme : VectorMapTheme(),
        super(key: key);

  final VectorMapDataSource? dataSource;
  final VectorMapTheme theme;
  final VectorMapTheme? hoverTheme;
  final double contourThickness;
  final int delayToRefreshResolution;
  final Color? borderColor;
  final double? borderThickness;
  final double? padding;
  final HoverRule? hoverRule;
  final HoverListener? hoverListener;
  final FeatureClickListener? clickListener;

  @override
  State<StatefulWidget> createState() => VectorMapState();
}

typedef FeatureClickListener = Function(MapFeature feature);

typedef HoverRule = bool Function(MapFeature feature);

typedef HoverListener = Function(MapFeature? feature);

class VectorMapState extends State<VectorMap> {
  MapFeature? _hover;

  MapResolution? _mapResolution;

  Size? _lastBuildSize;
  MapResolutionBuilder? _mapResolutionBuilder;

  _updateMapResolution(MapMatrices mapMatrices, Size size) {
    if (mounted && _lastBuildSize == size) {
      if (_mapResolutionBuilder != null) {
        _mapResolutionBuilder!.stop();
      }
      _mapResolutionBuilder = MapResolutionBuilder(
          dataSource: widget.dataSource!,
          theme: widget.theme,
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
    if (widget.dataSource != null) {
      content = LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        int? bufferWidth;
        int? bufferHeight;
        if (_mapResolution != null) {
          bufferWidth = _mapResolution!.mapBuffer.width;
          bufferHeight = _mapResolution!.mapBuffer.height;
        }
        MapMatrices mapMatrices = MapMatrices(
            widgetWidth: constraints.maxWidth,
            widgetHeight: constraints.maxHeight,
            geometryBounds: widget.dataSource!.bounds,
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

        MapPainter mapPainter = MapPainter(
            dataSource: widget.dataSource!,
            mapResolution: _mapResolution!,
            hover: _hover,
            mapMatrices: mapMatrices,
            contourThickness: widget.contourThickness,
            theme: widget.theme,
            hoverTheme: widget.hoverTheme);

        Widget map = CustomPaint(painter: mapPainter, child: Container());

        if ((widget.hoverTheme != null && widget.hoverTheme!.hasValue()) ||
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
      widget.clickListener!(_hover!);
    }
  }

  _onHover(PointerHoverEvent event, MapMatrices mapMatrices) {
    if (_mapResolution != null) {
      Offset o = MatrixUtils.transformPoint(
          mapMatrices.canvasMatrix.screenToGeometry, event.localPosition);

      bool found = false;
      for (MapFeature feature in widget.dataSource!.features.values) {
        if (widget.hoverRule != null && widget.hoverRule!(feature) == false) {
          continue;
        }
        if (_mapResolution!.paths.containsKey(feature.id) == false) {
          throw VectorMapError('No path for id: ' + feature.id.toString());
        }
        Path path = _mapResolution!.paths[feature.id]!;
        found = path.contains(o);
        if (found) {
          if (_hover != feature) {
            _updateHover(feature);
          }
          break;
        }
      }
      if (found == false && _hover != null) {
        _updateHover(null);
      }
    }
  }

  _updateHover(MapFeature? newHover) {
    if (widget.hoverTheme != null && widget.hoverTheme!.hasValue()) {
      // repaint
      setState(() {
        _hover = newHover;
      });
    } else {
      _hover = newHover;
    }
    if (widget.hoverListener != null) {
      widget.hoverListener!(newHover);
    }
  }
}

/// Painter for [VectorMap].
class MapPainter extends CustomPainter {
  MapPainter(
      {required this.mapResolution,
      required this.mapMatrices,
      required this.dataSource,
      required this.contourThickness,
      required this.theme,
      this.hoverTheme,
      this.hover});

  final MapMatrices mapMatrices;
  final double contourThickness;
  final VectorMapTheme theme;
  final VectorMapTheme? hoverTheme;
  final MapFeature? hover;
  final VectorMapDataSource dataSource;
  final MapResolution mapResolution;

  @override
  void paint(Canvas canvas, Size size) {
    // drawing the buffer

    canvas.save();
    BufferPaintMatrix matrix = mapMatrices.bufferPaintMatrix!;
    canvas.translate(matrix.translateX, matrix.translateY);
    canvas.scale(matrix.scale);
    canvas.drawImage(mapResolution.mapBuffer, Offset.zero, Paint());
    canvas.restore();

    // drawing the hover
    if (hover != null && hoverTheme != null) {
      Color? hoverColor = hoverTheme!.getColor(dataSource, hover!);
      if (hoverColor != null || hoverTheme!.contourColor != null) {
        canvas.save();

        CanvasMatrix canvasMatrix = mapMatrices.canvasMatrix;
        canvas.translate(canvasMatrix.translateX, canvasMatrix.translateY);
        canvas.scale(canvasMatrix.scale, -canvasMatrix.scale);

        int featureId = hover!.id;
        if (mapResolution.paths.containsKey(featureId) == false) {
          throw VectorMapError('No path for id: $featureId');
        }

        Path path = mapResolution.paths[featureId]!;

        if (hoverColor != null) {
          var paint = Paint()
            ..style = PaintingStyle.fill
            ..color = hoverColor
            ..isAntiAlias = true;

          canvas.drawPath(path, paint);
        }

        if (contourThickness > 0) {
          Color contourColor = VectorMapTheme.defaultContourColor;
          if (hoverTheme != null && hoverTheme!.contourColor != null) {
            contourColor = hoverTheme!.contourColor!;
          } else if (theme.contourColor != null) {
            contourColor = theme.contourColor!;
          }

          var paint = Paint()
            ..style = PaintingStyle.stroke
            ..color = contourColor
            ..strokeWidth = contourThickness / canvasMatrix.scale
            ..isAntiAlias = true;

          canvas.drawPath(path, paint);
        }

        canvas.restore();
      }
    }

    if (theme.labelVisibility != null ||
        (hoverTheme != null && hoverTheme!.labelVisibility != null)) {
      for (MapFeature feature in dataSource.features.values) {
        if (feature.label != null) {
          LabelVisibility? labelVisibility;
          if (hoverTheme != null &&
              hoverTheme!.labelVisibility != null &&
              hover == feature) {
            labelVisibility = hoverTheme!.labelVisibility;
          } else {
            labelVisibility = theme.labelVisibility;
          }

          if (labelVisibility != null && labelVisibility(feature)) {
            Color? featureColor;
            LabelStyleBuilder? labelStyleBuilder;

            if (hoverTheme != null && hover == feature) {
              featureColor = hoverTheme!.getColor(dataSource, feature);
              labelStyleBuilder = hoverTheme!.labelStyleBuilder;
            }

            if (featureColor == null) {
              featureColor = VectorMapTheme.getThemeOrDefaultColor(
                  dataSource, feature, theme);
            }
            if (labelStyleBuilder == null) {
              labelStyleBuilder = theme.labelStyleBuilder;
            }

            _drawLabel(canvas, feature, featureColor, labelStyleBuilder);
          }
        }
      }
    }
  }

  _drawLabel(Canvas canvas, MapFeature feature, Color featureColor,
      LabelStyleBuilder? labelStyleBuilder) {
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

    Path path = mapResolution.paths[feature.id]!;
    Rect bounds = MatrixUtils.transformRect(
        mapMatrices.canvasMatrix.geometryToScreen, path.getBounds());
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
