[![pub](https://img.shields.io/pub/v/vector_map.svg)](https://pub.dev/packages/vector_map) [![pub2](https://img.shields.io/badge/Flutter-%E2%9D%A4-red)](https://flutter.dev/) ![pub3](https://img.shields.io/badge/final%20version-as%20soon%20as%20possible-blue)

# Vector Map

* Compatible with GeoJSON
* Multi resolution with geometry simplification
* Highly customizable
* High performance
* Interactable
* Pure Flutter (no WebView/JavaScript)

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/vector_map_v1.gif)

## Examples

Simplified GeoJSONs will be used in the examples to demonstrate package usage.
The following examples will assume that GeoJSONs have already been loaded into Strings.
The full code is at https://github.com/caduandrade/vector_map_flutter_demo.

**polygons.json** ([link](https://raw.githubusercontent.com/caduandrade/vector_map_flutter_demo/main/assets/polygons.json))

Name | Seq | Rnd
--- | --- | ---
"Einstein" | 1 | "73"
"Newton" | 2 | "92"
"Galileu" | 3 | "10"
"Darwin" | 4 |
"Pasteur" | 5 | "77"
"Faraday" | 6 | "32"
"Arquimedes" | 7 | "87"
"Tesla" | 8 | "17"
"Lavoisier" | 9 |
"Kepler" | 10 | "32"
"Turing" | 11 | "93"

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

No properties are loaded, only the geometries.

```dart
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
```

## Creating the Widget

```dart
    MapLayer layer = MapLayer(dataSource: polygons);

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/get_started_v1.png)

## Reading GeoJSON properties

The `keys` argument defines which properties must be loaded.
The `parseToNumber` argument defines which properties will have numeric values in quotes parsed to numbers.
The `labelKey` defines which property will be used to display its values as feature labels.

```dart
    MapDataSource polygons = await MapDataSource.geoJSON(
        geojson: polygonsGeoJSON,
        keys: ['Seq', 'Rnd'],
        parseToNumber: ['Rnd'],
        labelKey: 'Rnd');
```

## Theme

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme(color: Colors.yellow, contourColor: Colors.red));

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/default_colors_v1.png)

### Label

Mapping label property:

```dart
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON, labelKey: 'Name');
```

Visibility:

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme(labelVisibility: (feature) => true));

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_visible_v1.png)

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme:
            MapTheme(labelVisibility: (feature) => feature.label == 'Darwin'));

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_rule_v1.png)

##### Label style

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

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_style_v1.png)

### Color by property value

Sets a color for each property value in GeoJSON. If a color is not set, the default color is used.

Mapping the property key:

```dart
    MapDataSource polygons = await MapDataSource.geoJSON(
        geojson: polygonsGeoJSON, keys: ['Seq'], labelKey: 'Seq');
```

Setting the colors for the property values:

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.value(
            contourColor: Colors.white,
            labelVisibility: (feature) => true,
            key: 'Seq',
            colors: {
              2: Colors.green,
              4: Colors.red,
              6: Colors.orange,
              8: Colors.blue
            }));

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/color_by_value_v2.png)

### Color by rule

The feature color is obtained from the first rule that returns a non-null color. If all rules return a null color, the default color is used.

Mapping the property key:

```dart
    MapDataSource polygons = await MapDataSource.geoJSON(
        geojson: polygonsGeoJSON, keys: ['Name', 'Seq']);
```

Setting the rules:

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.rule(contourColor: Colors.white, colorRules: [
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

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/color_by_rule_v1.png)

### Gradient

The gradient is created given the colors and limit values of the chosen property.
The property must have numeric values.

##### Auto min/max values

Uses the min and max values read from data source.

```dart
    MapDataSource polygons = await MapDataSource.geoJSON(
        geojson: polygonsGeoJSON, keys: ['Seq'], labelKey: 'Seq');
```

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.gradient(
            contourColor: Colors.white,
            labelVisibility: (feature) => true,
            key: 'Seq',
            colors: [Colors.blue, Colors.yellow, Colors.red]));

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_auto_v2.png)

##### Setting min or max values manually

If the `min` value is set, all lower values will be displayed using the first gradient color.
If the `max` value is set, all higher values will be displayed using the last gradient color.

```dart
    MapDataSource polygons = await MapDataSource.geoJSON(
        geojson: polygonsGeoJSON, keys: ['Seq'], labelKey: 'Seq');
```

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.gradient(
            contourColor: Colors.white,
            labelVisibility: (feature) => true,
            key: 'Seq',
            min: 3,
            max: 9,
            colors: [Colors.blue, Colors.yellow, Colors.red]));

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_min_max_v2.png)

## Contour

#### Thickness

```dart
    VectorMap map = VectorMap(
        layers: [MapLayer(dataSource: polygons)], contourThickness: 3);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/contour_thickness_v1.png)

## Hover theme

#### Color

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons, hoverTheme: MapTheme(color: Colors.green));

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/hover_color_v1.png)

#### Contour color

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons, hoverTheme: MapTheme(contourColor: Colors.red));

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/hover_contour_v1.png)

#### Label

```dart
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON, labelKey: 'Name');
```

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons,
        hoverTheme: MapTheme(labelVisibility: (feature) => true));

    VectorMap map = VectorMap(layers: [layer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_hover_v1.png)

#### Listener

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons, hoverTheme: MapTheme(color: Colors.grey[700]));

    VectorMap map = VectorMap(
        layers: [layer],
        hoverListener: (MapFeature? feature) {
          if (feature != null) {
            int id = feature.id;
            print('Hover - Feature id: $id');
          }
        });
```

#### Rule

##### Enabling hover by property value

```dart
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON, keys: ['Seq']);
```

```dart
    // coloring only the 'Darwin' feature
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme.value(key: 'Seq', colors: {4: Colors.green}),
        hoverTheme: MapTheme(color: Colors.green[900]!));

    // enabling hover only for the 'Darwin' feature
    VectorMap map = VectorMap(
        layers: [layer],
        hoverRule: (feature) {
          return feature.getValue('Seq') == 4;
        });
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/enable_hover_by_value_v1.gif)

## Layers

Loading multiple data sources:

```dart
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
    MapDataSource points = await MapDataSource.geoJSON(geojson: pointsGeoJSON);
```

Creating a map with multiple layers:

```dart
    MapTheme hoverTheme = MapTheme(color: Colors.green);

    MapLayer polygonsLayer =
        MapLayer(dataSource: polygons, hoverTheme: hoverTheme);
    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(color: Colors.black),
        hoverTheme: hoverTheme);

    VectorMap map = VectorMap(layers: [polygonsLayer, pointsLayer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/multiple_layers_v1.gif)

#### Overlay hover contour

```dart
    MapDataSource dataSource1 = MapDataSource.geometries([
      MapPolygon.coordinates([2, 3, 4, 5, 6, 3, 4, 1, 2, 3])
    ]);
    MapDataSource dataSource2 = MapDataSource.geometries([
      MapPolygon.coordinates([0, 2, 2, 4, 4, 2, 2, 0, 0, 2]),
      MapPolygon.coordinates([4, 2, 6, 4, 8, 2, 6, 0, 4, 2])
    ]);

    MapTheme hoverTheme =
        MapTheme(color: Colors.black, contourColor: Colors.black);

    MapLayer layer1 = MapLayer(
        dataSource: dataSource1,
        theme: MapTheme(color: Colors.yellow, contourColor: Colors.black),
        hoverTheme: hoverTheme);
    MapLayer layer2 = MapLayer(
        dataSource: dataSource2,
        theme: MapTheme(color: Colors.green, contourColor: Colors.black),
        hoverTheme: hoverTheme);
```

Overlay disabled:

```dart
    VectorMap map = VectorMap(layers: [layer1, layer2]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/overlay_contour_off_v1.gif)

Overlay enabled:

```dart
    VectorMap map =
        VectorMap(layers: [layer1, layer2], overlayHoverContour: true);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/overlay_contour_on_v1.gif)

## Marker

Allows different displays for point geometry.

#### Circle marker

Default marker.

##### Fixed radius

Sets a fixed size radius.

```dart
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
    MapDataSource points =
        await MapDataSource.geoJSON(geojson: pointsGeoJSON, keys: ['AN']);
```

```dart
    MapLayer polygonsLayer = MapLayer(dataSource: polygons);

    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(
            color: Colors.black,
            markerBuilder: CircleMakerBuilder.fixed(radius: 15)));

    VectorMap map = VectorMap(layers: [polygonsLayer, pointsLayer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/circle_marker_fixed_v1.png)

##### Radius by mapping values

Maps property values to radius values.

```dart
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
    MapDataSource points = await MapDataSource.geoJSON(
        geojson: pointsGeoJSON, keys: ['AN'], labelKey: 'AN');
```

```dart
    MapLayer polygonsLayer = MapLayer(dataSource: polygons);

    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(
            color: Colors.black,
            labelVisibility: (feature) => true,
            markerBuilder: CircleMakerBuilder.map(
                key: 'AN', radiuses: {41: 25, 22: 20, 14: 10, 10: 10})));

    VectorMap map = VectorMap(layers: [polygonsLayer, pointsLayer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/circle_marker_map_v2.png)

##### Radius by property values

Uses the property values as radius values.

```dart
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
    MapDataSource points = await MapDataSource.geoJSON(
        geojson: pointsGeoJSON, keys: ['AN'], labelKey: 'AN');
```

```dart
    MapLayer polygonsLayer = MapLayer(dataSource: polygons);

    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(
            color: Colors.black,
            labelVisibility: (feature) => true,
            markerBuilder: CircleMakerBuilder.property(key: 'AN')));

    VectorMap map = VectorMap(layers: [polygonsLayer, pointsLayer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/circle_marker_property_v2.png)

##### Radius in proportion to property values

```dart
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
    MapDataSource points = await MapDataSource.geoJSON(
        geojson: pointsGeoJSON, keys: ['AN'], labelKey: 'AN');
```

```dart
    MapLayer polygonsLayer = MapLayer(dataSource: polygons);

    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(
            color: Colors.black,
            labelVisibility: (feature) => true,
            markerBuilder: CircleMakerBuilder.proportion(
                key: 'AN', minRadius: 8, maxRadius: 30)));

    VectorMap map = VectorMap(layers: [polygonsLayer, pointsLayer]);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/circle_marker_proportion_v2.png)

## Click listener

```dart
    MapLayer layer = MapLayer(
        dataSource: polygons, hoverTheme: MapTheme(color: Colors.grey[800]!));

    VectorMap map = VectorMap(
        layers: [layer],
        clickListener: (feature) {
          print(feature.id);
        });
```

## Agenda for the next few days

* More theming features
* Zoom / Pan
* Legend
* Release the final version (1.0.0). The API may have some small changes.