import 'package:demo/menu.dart';
import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class LabelPage extends StatefulWidget {
  @override
  LabelPageState createState() => LabelPageState();
}

class LabelPageState extends ExamplePageState {
  @override
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, labelKey: 'Name');
    return dataSource;
  }

  List<MenuItem> buildMenuItems() {
    return [
      MenuItem('All visible', _allVisible),
      MenuItem('Visible rule', _visibleRule),
      MenuItem('Label style', _labelStyle)
    ];
  }

  Widget _allVisible() {
    VectorMap map = VectorMap(
        dataSource: dataSource,
        theme: VectorMapTheme(labelVisibility: (feature) => true));

    return map;
  }

  Widget _visibleRule() {
    VectorMap map = VectorMap(
        dataSource: dataSource,
        theme: VectorMapTheme(
            labelVisibility: (feature) => feature.label == 'Darwin'));

    return map;
  }

  Widget _labelStyle() {
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

    return map;
  }
}
