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
  Future<VectorMapDataSource> loadDataSource(String geojson) async {
    VectorMapDataSource dataSource =
        await VectorMapDataSource.geoJSON(geojson: geojson, labelKey: 'Name');
    return dataSource;
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
    VectorMap map = VectorMap(
        dataSource: dataSource,
        hoverTheme: VectorMapTheme(color: Colors.grey[700]),
        hoverListener: (MapFeature? feature) {
          if (feature != null) {
            int id = feature.id;
            print('Hover - Feature id: $id');
          }
        });

    return map;
  }

  Widget _color() {
    VectorMap map = VectorMap(
        dataSource: dataSource,
        hoverTheme: VectorMapTheme(color: Colors.green));

    return map;
  }

  Widget _contourColor() {
    VectorMap map = VectorMap(
        dataSource: dataSource,
        hoverTheme: VectorMapTheme(contourColor: Colors.red));

    return map;
  }

  Widget _label() {
    VectorMap map = VectorMap(
        dataSource: dataSource,
        hoverTheme: VectorMapTheme(labelVisibility: (feature) => true));

    return map;
  }

  Widget _override() {
    VectorMap map = VectorMap(
        dataSource: dataSource,
        theme: VectorMapTheme(
            color: Colors.white, labelVisibility: (feature) => false),
        hoverTheme: VectorMapTheme.rule(colorRules: [
          (feature) {
            return feature.label == 'Galileu' ? Colors.blue : null;
          }
        ], labelVisibility: (feature) => feature.label == 'Galileu'));

    return map;
  }
}
