[![pub](https://img.shields.io/pub/v/vector_map.svg)](https://pub.dev/packages/vector_map) [![pub2](https://img.shields.io/badge/Flutter-%E2%9D%A4-red)](https://flutter.dev/) ![pub3](https://img.shields.io/badge/final%20version-as%20soon%20as%20possible-blue)

# Vector Map

* Displays GeoJSON geometries
* Multi resolution with geometry simplification
* Highly customizable
* Interactable
* Pure Flutter (no WebView/JavaScript)

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/vector_map_v1.gif)

## Get started

A simplified GeoJSON will be used in the examples to demonstrate the different possibilities of themes. This GeoJSON has only 3 features with the following properties:

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

To view the full content, use this [link](https://raw.githubusercontent.com/caduandrade/vector_map_flutter/main/demo/assets/example.json).

The following examples will assume that GeoJSON has already been loaded into a String.

##### Reading GeoJSON from String

No properties are loaded, only the geometries.

```dart
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson);
```

##### Creating the Widget

```dart
    VectorMap map = VectorMap(dataSource: dataSource);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/get_started_v1.png)

##### Reading GeoJSON properties

The `keys` argument defines which properties must be loaded.
The `parseToNumber` argument defines which properties will have numeric values in quotes parsed to numbers.

```dart
    VectorMapDataSource dataSource = await VectorMapDataSource.geoJSON(
        geojson: geojson, keys: ['Seq', 'Rnd'], parseToNumber: ['Rnd']);
```

## Default colors

```dart
    VectorMap map = VectorMap(
        dataSource: dataSource,
        theme: VectorMapTheme(color: Colors.yellow, contourColor: Colors.red));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/default_colors_v1.png)

## Color by property value

Sets a color for each property value in GeoJSON. If a color is not set, the default color is used.

##### Mapping the property key

```dart
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, keys: ['Seq']);
```

##### Setting the colors for the property values

```dart
    VectorMapTheme theme = VectorMapTheme.value(
        contourColor: Colors.white,
        key: 'Seq',
        colors: {
          2: Colors.green,
          4: Colors.red,
          6: Colors.orange,
          8: Colors.blue
        });

    VectorMap map = VectorMap(dataSource: dataSource, theme: theme);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/color_by_value_v1.png)

## Color by rule

The feature color is obtained from the first rule that returns a non-null color. If all rules return a null color, the default color is used.

##### Mapping the property key

```dart
    VectorMapDataSource dataSource = await VectorMapDataSource.geoJSON(
        geojson: geojson, keys: ['Name', 'Seq']);
```

##### Setting the rules

```dart
    VectorMapTheme theme =
        VectorMapTheme.rule(contourColor: Colors.white, colorRules: [
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
    ]);

    VectorMap map = VectorMap(dataSource: dataSource, theme: theme);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/color_by_rule_v1.png)

## Gradient

The gradient is created given the colors and limit values of the chosen property.
The property must have numeric values.

#### Auto min/max values

Uses the min and max values read from data source.

```dart
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, keys: ['Seq']);
```

```dart
    VectorMapTheme theme = VectorMapTheme.gradient(
        contourColor: Colors.white,
        key: 'Seq',
        colors: [Colors.blue, Colors.yellow, Colors.red]);

    VectorMap map = VectorMap(dataSource: dataSource, theme: theme);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_auto_v1.png)

#### Setting min or max values manually

If the `min` value is set, all lower values will be displayed using the first gradient color.
If the `max` value is set, all higher values will be displayed using the last gradient color.

```dart
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, keys: ['Seq']);
```

```dart
    VectorMapTheme theme = VectorMapTheme.gradient(
        contourColor: Colors.white,
        key: 'Seq',
        min: 3,
        max: 9,
        colors: [Colors.blue, Colors.yellow, Colors.red]);

    VectorMap map = VectorMap(dataSource: dataSource, theme: theme);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/gradient_min_max_v1.png)

## Contour

#### Thickness

```dart
    VectorMap map = VectorMap(dataSource: dataSource, contourThickness: 3);
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/contour_thickness_v1.png)

## Label

#### Mapping label property

```dart
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, labelKey: 'Name');
```

#### Visibility

```dart
    VectorMap map = VectorMap(
        dataSource: dataSource,
        theme: VectorMapTheme(labelVisibility: (feature) => true));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_visible_v1.png)

```dart
    VectorMap map = VectorMap(
        dataSource: dataSource,
        theme: VectorMapTheme(
            labelVisibility: (feature) => feature.label == 'Darwin'));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_rule_v1.png)

#### Style

```dart
    VectorMap map = VectorMap(
        dataSource: dataSource,
        theme: VectorMapTheme(
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

## Hover

#### Color

```dart
    VectorMap map = VectorMap(
        dataSource: dataSource, hoverTheme: VectorMapTheme(color: Colors.green));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/hover_color_v1.png)

#### Contour color

```dart
    VectorMap map = VectorMap(
        dataSource: dataSource,
        hoverTheme: VectorMapTheme(contourColor: Colors.red));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/hover_contour_v1.png)

#### Label

```dart
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, labelKey: 'Name');
```

```dart
    VectorMap map = VectorMap(
        dataSource: dataSource,
        hoverTheme: VectorMapTheme(labelVisibility: (feature) => true));
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/label_hover_v1.png)

#### Listener

```dart
    VectorMap map = VectorMap(
        dataSource: dataSource,
        hoverTheme: VectorMapTheme(color: Colors.grey[700]),
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
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, keys: ['Seq']);
```

```dart
    // coloring only the 'Darwin' feature
    VectorMapTheme theme =
        VectorMapTheme.value(key: 'Seq', colors: {4: Colors.green});
    VectorMapTheme hoverTheme = VectorMapTheme(color: Colors.green[900]!);

    // enabling hover only for the 'Darwin' feature
    VectorMap map = VectorMap(
      dataSource: dataSource,
      theme: theme,
      hoverTheme: hoverTheme,
      hoverRule: (feature) {
        return feature.getValue('Seq') == 4;
      },
    );
```

![](https://raw.githubusercontent.com/caduandrade/images/main/vector_map/enable_hover_by_value_v1.gif)

## Click listener

```dart
    VectorMap map = VectorMap(
        dataSource: dataSource,
        hoverTheme: VectorMapTheme(color: Colors.grey[800]!),
        clickListener: (feature) {
          print(feature.id);
        });
```

## Agenda for the next few days

* More theming features
* Zoom / Pan
* Layers
* Legend
* Release the final version (1.0.0). The API may have some small changes.