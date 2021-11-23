[![pub](https://img.shields.io/pub/v/vector_map.svg)](https://pub.dev/packages/vector_map) [![pub2](https://img.shields.io/badge/Flutter-%E2%9D%A4-red)](https://flutter.dev/) ![pub3](https://img.shields.io/badge/final%20version-as%20soon%20as%20possible-blue)

# Vector Map

* Compatible with GeoJSON
* Multi resolution with geometry simplification
* Highly customizable
* High performance
* Interactable
* Pure Flutter (no WebView/JavaScript)

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/vector_map_v1.png)

## Usage

* [About the examples](#about-the-examples)
* [Reading GeoJSON from String](#reading-geojson-from-string)
* [Reading GeoJSON properties](#reading-geojson-properties)
* [Creating the Widget](#creating-the-widget)
* [Theme](#theme)
  * [Label visibility](#label-visibility)
  * [Label style](#label-style)
  * [Color by property value](#color-by-property-value)
  * [Color by rule](#color-by-rule)
  * [Gradient](#gradient)
* [Highlight theme](#highlight-theme)
* [Contour thickness](#contour-thickness)
* Cursor hover
  * [Rule](#cursor-hover-rule)
  * [Listener](#cursor-hover-listener)
* [Layers](#layers)
  * [Overlay hover contour](#overlay-hover-contour)
* [Marker](#marker)
  * Circle
    * [Fixed radius](#fixed-radius)
    * [Radius by mapping values](#radius-by-mapping-values)
    * [Radius by property values](#radius-by-property-values)
    * [Radius in proportion to property values](#radius-in-proportion-to-property-values)
* [Addons](#addons)
  * [Legend](#legend)
    * [Gradient legend](#gradient-legend)
      * [Setting min and max values](#gradient-legend---setting-min-and-max-values)
      * [Highlight](#gradient-legend---highlight)
      * [Customization](#gradient-legend---customization)
* [Click listener](#click-listener)
* [Debugger](#debugger)

## About the examples

Simplified GeoJSONs will be used in the examples to demonstrate package usage.
The following examples will assume that GeoJSONs have already been loaded into Strings.
The full code is at https://github.com/caduandrade/vector_map_flutter_demo.

**polygons.json** ([link](https://raw.githubusercontent.com/caduandrade/vector_map_flutter_demo/main/assets/polygons.json))

Name | Seq | Rnd | Gts
--- | --- | --- | ---
"Einstein" | 1 | "73" | 15000
"Newton" | 2 | "92" | 7500
"Galileu" | 3 | "10" | 3000
"Darwin" | 4 |  | 15000
"Pasteur" | 5 | "77" | 17000
"Faraday" | 6 | "32" | 17500
"Arquimedes" | 7 | "87" | 25000
"Tesla" | 8 | "17" | 12500
"Lavoisier" | 9 |  | 4000
"Kepler" | 10 | "32" | 18000
"Turing" | 11 | "93" | 31400

**points.json** ([link](https://raw.githubusercontent.com/caduandrade/vector_map_flutter_demo/main/assets/points.json))

Name | AN
--- | ---
"Titanium" | 22
"Niobium" | 41
"Carbon" | 6
"Neon" | 10
"Silicon" | 14
"Hydrogen" | 1

## Reading GeoJSON from String

Reading the geometries only.

```dart
  MapDataSource polygons = await MapDataSource.geoJson(geoJson: geoJson);
```

## Reading GeoJSON properties

The `keys` argument defines which properties must be loaded.
The `parseToNumber` argument defines which properties will have numeric values in quotes parsed to numbers.
The `labelKey` defines which property will be used to display its values as feature labels.

```dart
  MapDataSource polygons = await MapDataSource.geoJson(
      geoJson: geoJson,
      keys: ['Seq', 'Rnd'],
      parseToNumber: ['Rnd'],
      labelKey: 'Rnd');
```

## Creating the Widget

```dart
  VectorMapController _controller = VectorMapController();
```

```dart
  MapDataSource polygons = await MapDataSource.geoJson(geoJson: geoJson);
  MapLayer layer = MapLayer(dataSource: polygons);
  _controller.addLayer(layer);
```

```dart
  VectorMap map = VectorMap(controller: _controller);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/get_started_v1.png)


## Theme

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapTheme(color: Colors.yellow, contourColor: Colors.red));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/default_colors_v1.png)

### Label visibility

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: geoJson, labelKey: 'Name');
```

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapTheme(labelVisibility: (feature) => true));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_visible_v1.png)

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapTheme(labelVisibility: (feature) => feature.label == 'Darwin'));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_rule_v1.png)

### Label style

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapTheme(
          labelVisibility: (feature) => true,
          labelStyleBuilder: (feature, featureColor, labelColor) {
            if (feature.label == 'Darwin') {
              return TextStyle(
                color: labelColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              );
            }
            return TextStyle(
              color: labelColor,
              fontSize: 11,
            );
          }));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_style_v1.png)

### Color by property value

Sets a color for each property value in GeoJSON. If a color is not set, the default color is used.

Mapping the property key:

```dart
  MapDataSource polygons = await MapDataSource.geoJson(
      geoJson: geoJson, keys: ['Seq'], labelKey: 'Seq');
```

Setting the colors for the property values:

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapValueTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Seq',
          colors: {
            2: Colors.green,
            4: Colors.red,
            6: Colors.orange,
            8: Colors.blue
          }));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/color_by_value_v2.png)

### Color by rule

The feature color is obtained from the first rule that returns a non-null color. If all rules return a null color, the default color is used.

Mapping the property key:

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: geoJson, keys: ['Name', 'Seq']);
```

Setting the rules:

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapRuleTheme(contourColor: Colors.white, colorRules: [
        (feature) {
          String? value = feature.getValue('Name');
          return value == 'Faraday' ? Colors.red : null;
        },
        (feature) {
          double? value = feature.getDoubleValue('Seq');
          return value != null && value < 3 ? Colors.green : null;
        },
        (feature) {
          double? value = feature.getDoubleValue('Seq');
          return value != null && value > 9 ? Colors.blue : null;
        }
      ]));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/color_by_rule_v1.png)

### Gradient

The gradient is created given the colors and limit values of the chosen property.
The property must have numeric values.

#### Auto min/max values

Uses the min and max values read from data source.

```dart
  MapDataSource polygons = await MapDataSource.geoJson(
      geoJson: geoJson, keys: ['Seq'], labelKey: 'Seq');
```

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapGradientTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Seq',
          colors: [Colors.blue, Colors.yellow, Colors.red]));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_auto_v2.png)

#### Setting min or max values manually

If the `min` value is set, all lower values will be displayed using the first gradient color.
If the `max` value is set, all higher values will be displayed using the last gradient color.

```dart
  MapDataSource polygons = await MapDataSource.geoJson(
      geoJson: geoJson, keys: ['Seq'], labelKey: 'Seq');
```

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapGradientTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Seq',
          min: 3,
          max: 9,
          colors: [Colors.blue, Colors.yellow, Colors.red]));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_min_max_v2.png)

## Highlight theme

Used by addons and cursor hover to highlight layer features on the map.

### Color

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      highlightTheme: MapHighlightTheme(color: Colors.green));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/hover_color_v1.png)

### Contour color

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      highlightTheme: MapHighlightTheme(contourColor: Colors.red));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/hover_contour_v1.png)

### Label

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: geoJson, labelKey: 'Name');
```

```dart
  MapLayer layer = MapLayer(
      dataSource: polygons,
      highlightTheme: MapHighlightTheme(labelVisibility: (feature) => true));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_hover_v1.png)

## Contour thickness

```dart
  VectorMapController _controller = VectorMapController(contourThickness: 3);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/contour_thickness_v1.png)

## Cursor hover rule

### Enabling hover by property value

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: geoJson, keys: ['Seq']);
```

```dart
  // coloring only the 'Darwin' feature
  MapLayer layer = MapLayer(
      dataSource: polygons,
      theme: MapValueTheme(key: 'Seq', colors: {4: Colors.green}),
      highlightTheme: MapHighlightTheme(color: Colors.green[900]!));
```

```dart
  // enabling hover only for the 'Darwin' feature
  VectorMap map = VectorMap(
      controller: _controller,
      hoverRule: (feature) {
        return feature.getValue('Seq') == 4;
      });
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/enable_hover_by_value_v1.gif)

## Cursor hover listener

```dart
  VectorMap map = VectorMap(
      controller: _controller,
      hoverListener: (MapFeature? feature) {
        if (feature != null) {
          int id = feature.id;
        }
      });
```

## Layers

```dart
  MapHighlightTheme highlightTheme = MapHighlightTheme(color: Colors.green);

  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: polygonsGeoJson);
  MapLayer polygonLayer =
      MapLayer(dataSource: polygons, highlightTheme: highlightTheme);
  _controller.addLayer(polygonLayer);

  MapDataSource points = await MapDataSource.geoJson(geoJson: pointsGeoJson);
  MapLayer pointsLayer = MapLayer(
      dataSource: points,
      theme: MapTheme(color: Colors.black),
      highlightTheme: highlightTheme);
  _controller.addLayer(pointsLayer);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/multiple_layers_v1.gif)

### Overlay hover contour

Allows you to draw the contour over all layers

```dart
  MapDataSource dataSource1 = MapDataSource.geometries([
    MapPolygon.coordinates([2, 3, 4, 5, 6, 3, 4, 1, 2, 3])
  ]);
  MapDataSource dataSource2 = MapDataSource.geometries([
    MapPolygon.coordinates([0, 2, 2, 4, 4, 2, 2, 0, 0, 2]),
    MapPolygon.coordinates([4, 2, 6, 4, 8, 2, 6, 0, 4, 2])
  ]);
```

Overlay disabled:

```dart
  MapHighlightTheme highlightTheme =
      MapHighlightTheme(color: Colors.black, contourColor: Colors.black);

  MapLayer layer1 = MapLayer(
      dataSource: dataSource1,
      theme: MapTheme(color: Colors.yellow, contourColor: Colors.black),
      highlightTheme: highlightTheme);
  MapLayer layer2 = MapLayer(
      dataSource: dataSource2,
      theme: MapTheme(color: Colors.green, contourColor: Colors.black),
      highlightTheme: highlightTheme);

  _controller = VectorMapController(layers: [layer1, layer2]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/overlay_contour_off_v1.gif)

Overlay enabled:

```dart
  MapLayer layer1 = MapLayer(
      dataSource: dataSource1,
      theme: MapTheme(color: Colors.yellow, contourColor: Colors.black),
      highlightTheme: MapHighlightTheme(
          color: Colors.black,
          contourColor: Colors.black,
          overlayContour: true));
  MapLayer layer2 = MapLayer(
      dataSource: dataSource2,
      theme: MapTheme(color: Colors.green, contourColor: Colors.black),
      highlightTheme:
          MapHighlightTheme(color: Colors.black, contourColor: Colors.black));

  _controller = VectorMapController(layers: [layer1, layer2]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/overlay_contour_on_v1.gif)

## Marker

Allows different displays for point geometry.

### Circle marker

Default marker.

#### Fixed radius

Sets a fixed size radius.

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: polygonsGeoJson);
  MapLayer polygonsLayer = MapLayer(dataSource: polygons);
  _controller.addLayer(polygonsLayer);

  MapDataSource points = await MapDataSource.geoJson(
      geoJson: pointsGeoJson, keys: ['AN'], labelKey: 'AN');
  MapLayer pointsLayer = MapLayer(
      dataSource: points,
      theme: MapTheme(
          color: Colors.black,
          markerBuilder: CircleMakerBuilder.fixed(radius: 15)));
  _controller.addLayer(pointsLayer);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/circle_marker_fixed_v1.png)

#### Radius by mapping values

Maps property values to radius values.

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: polygonsGeoJson);
  MapLayer polygonsLayer = MapLayer(dataSource: polygons);
  _controller.addLayer(polygonsLayer);

  MapDataSource points = await MapDataSource.geoJson(
      geoJson: pointsGeoJson, keys: ['AN'], labelKey: 'AN');
  MapLayer pointsLayer = MapLayer(
      dataSource: points,
      theme: MapTheme(
          color: Colors.black,
          labelVisibility: (feature) => true,
          markerBuilder: CircleMakerBuilder.map(
              key: 'AN', radiuses: {41: 25, 22: 20, 14: 10, 10: 10})));
  _controller.addLayer(pointsLayer);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/circle_marker_map_v2.png)

#### Radius by property values

Uses the property values as radius values.

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: polygonsGeoJson);
  MapLayer polygonsLayer = MapLayer(dataSource: polygons);
  _controller.addLayer(polygonsLayer);

  MapDataSource points = await MapDataSource.geoJson(
      geoJson: pointsGeoJson, keys: ['AN'], labelKey: 'AN');
  MapLayer pointsLayer = MapLayer(
      dataSource: points,
      theme: MapTheme(
          color: Colors.black,
          labelVisibility: (feature) => true,
          markerBuilder: CircleMakerBuilder.property(key: 'AN')));
  _controller.addLayer(pointsLayer);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/circle_marker_property_v2.png)

#### Radius in proportion to property values

```dart
  MapDataSource polygons =
      await MapDataSource.geoJson(geoJson: polygonsGeoJson);
  MapLayer polygonsLayer = MapLayer(dataSource: polygons);
  _controller.addLayer(polygonsLayer);

  MapDataSource points = await MapDataSource.geoJson(
      geoJson: pointsGeoJson, keys: ['AN'], labelKey: 'AN');
  MapLayer pointsLayer = MapLayer(
      dataSource: points,
      theme: MapTheme(
          color: Colors.black,
          labelVisibility: (feature) => true,
          markerBuilder: CircleMakerBuilder.proportion(
              key: 'AN', minRadius: 8, maxRadius: 30)));
  _controller.addLayer(pointsLayer);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/circle_marker_proportion_v2.png)

## Addons

Allows adding components on the map.

### Legend

Available customizations:

* padding
* margin
* decoration

#### Gradient legend

Legend for gradient themes.

```dart
  MapDataSource polygons = await MapDataSource.geoJson(
      geoJson: geoJson, keys: ['Gts'], labelKey: 'Gts');
```

```dart
  MapLayer layer = MapLayer(
      id: 1,
      dataSource: polygons,
      theme: MapGradientTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Gts',
          colors: [Colors.blue, Colors.yellow, Colors.red]));
  _controller.addLayer(layer);
```

```dart
  _addons = [GradientLegend(layer: layer)];
```

```dart
  VectorMap map = VectorMap(
      controller: _controller,
      layersPadding: EdgeInsets.fromLTRB(8, 8, 56, 8),
      addons: _addons);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_legend_v2.png)

##### Gradient legend - Setting min and max values

```dart
  MapLayer layer = MapLayer(
      id: 1,
      dataSource: polygons,
      theme: MapGradientTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Gts',
          min: 7500,
          max: 25000,
          colors: [Colors.blue, Colors.yellow, Colors.red]));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_legend_min_max_v1.png)

##### Gradient legend - Highlight

```dart
  MapLayer layer = MapLayer(
      id: 1,
      dataSource: polygons,
      theme: MapGradientTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Gts',
          min: 7500,
          max: 25000,
          colors: [Colors.blue, Colors.yellow, Colors.red]),
      highlightTheme: MapHighlightTheme(color: Colors.brown[900]));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_legend_highlight_fill_v1.png)

##### Gradient legend - Customization

Available customizations:

* gradient bar width
* gradient bar height
* gradient bar border
* values font size
* gap between bar and values

```dart
  MapLayer layer = MapLayer(
      id: 1,
      dataSource: polygons,
      theme: MapGradientTheme(
          contourColor: Colors.white,
          labelVisibility: (feature) => true,
          key: 'Gts',
          colors: [Colors.blue, Colors.yellow, Colors.red]));
```

```dart
  _addons = [
    GradientLegend(
        layer: layer,
        barBorder: Border.all(width: 2),
        barHeight: 50,
        barWidth: 30)
  ];
```

```dart
  VectorMap map = VectorMap(
      controller: _controller,
      layersPadding: EdgeInsets.fromLTRB(8, 8, 56, 8),
      addons: _addons);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_legend_custom_v1.png)


## Click listener

```dart
  VectorMap map = VectorMap(
      controller: _controller,
      clickListener: (feature) {
        print('feature id: ${feature.id}');
      });
```

## Debugger

Building a debugger

```dart
  MapDebugger debugger = MapDebugger();
```

Binding the debugger on the map

```dart
  _controller = VectorMapController(debugger: widget.debugger);
```

Building the debugger widget

```dart
  MapDebuggerWidget debuggerWidget = MapDebuggerWidget(debugger);
```

![](https://caduandrade.github.io/vector_map/debugger_v1.png)

## ToDo

* More theming features
* More legends
  * More gradient legend customizations
* More addons
* Release the final version (1.0.0). The API may have some small changes.