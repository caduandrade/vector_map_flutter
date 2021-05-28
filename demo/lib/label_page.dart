import 'package:demo/menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class LabelPage extends StatefulWidget {
  @override
  LabelPageState createState() => LabelPageState();
}

class LabelPageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON, labelKey: 'Name');
    return DataSources(polygons: polygons);
  }

  List<MenuItem> buildMenuItems() {
    return [
      MenuItem('All visible', _allVisible),
      MenuItem('Visible rule', _visibleRule),
      MenuItem('Label style', _labelStyle)
    ];
  }

  Widget _allVisible() {
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme: MapTheme(labelVisibility: (feature) => true));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }

  Widget _visibleRule() {
    MapLayer layer = MapLayer(
        dataSource: polygons,
        theme:
            MapTheme(labelVisibility: (feature) => feature.label == 'Darwin'));

    VectorMap map = VectorMap(layers: [layer]);

    return map;
  }

  Widget _labelStyle() {
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

    return map;
  }
}
