import 'package:demo/menu.dart';
import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class HoverPage extends StatefulWidget {
  @override
  HoverPageState createState() => HoverPageState();
}

class HoverPageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON, labelKey: 'Name');
    return DataSources(polygons: polygons);
  }

  @override
  List<MenuItem> buildMenuItems() {
    return [
      MenuItem('Color', _color),
      MenuItem('Contour', _contourColor),
      MenuItem('Label', _label),
      MenuItem('Override', _override),
      MenuItem('Listener', _listener)
    ];
  }

  Widget _listener() {
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

    return map;
  }

  Widget _color() {
    MapLayer layer = MapLayer(
        dataSource: polygons, hoverTheme: MapTheme(color: Colors.green));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }

  Widget _contourColor() {
    MapLayer layer = MapLayer(
        dataSource: polygons, hoverTheme: MapTheme(contourColor: Colors.red));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }

  Widget _label() {
    MapLayer layer = MapLayer(
        dataSource: polygons,
        hoverTheme: MapTheme(labelVisibility: (feature) => true));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }

  Widget _override() {
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme:
            MapTheme(color: Colors.white, labelVisibility: (feature) => false),
        hoverTheme: MapTheme.rule(colorRules: [
          (feature) {
            return feature.label == 'Galileu' ? Colors.blue : null;
          }
        ], labelVisibility: (feature) => feature.label == 'Galileu'));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }
}
