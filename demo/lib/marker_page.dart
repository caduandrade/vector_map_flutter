import 'package:demo/menu.dart';
import 'package:flutter/material.dart';
import 'package:vector_map/vector_map.dart';

import 'example_page.dart';

class MarkerPage extends StatefulWidget {
  @override
  MarkerPageState createState() => MarkerPageState();
}

class MarkerPageState extends ExamplePageState {
  @override
  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON) async {
    MapDataSource polygons =
        await MapDataSource.geoJSON(geojson: polygonsGeoJSON);
    MapDataSource points =
        await MapDataSource.geoJSON(geojson: pointsGeoJSON, keys: ['AN']);
    return DataSources(polygons: polygons, points: points);
  }

  @override
  List<MenuItem> buildMenuItems() {
    return [
      MenuItem('Default marker', _defaultMarker),
      MenuItem('Circle radius', _circleRadius),
      MenuItem('Circle radius by value', _circleRadiusByValue)
    ];
  }

  Widget _defaultMarker() {
    MapTheme hoverTheme = MapTheme(color: Colors.green);

    MapLayer polygonsLayer =
        MapLayer(dataSource: polygons, hoverTheme: hoverTheme);

    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(color: Colors.black),
        hoverTheme: hoverTheme);

    VectorMap map = VectorMap(layers: [polygonsLayer, pointsLayer]);
    return map;
  }

  Widget _circleRadius() {
    MapTheme hoverTheme = MapTheme(color: Colors.green);

    MapLayer polygonsLayer =
        MapLayer(dataSource: polygons, hoverTheme: hoverTheme);

    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(
            color: Colors.black, markerBuilder: CircleMakerBuilder(radius: 15)),
        hoverTheme: hoverTheme);

    VectorMap map = VectorMap(layers: [polygonsLayer, pointsLayer]);
    return map;
  }

  Widget _circleRadiusByValue() {
    MapTheme hoverTheme = MapTheme(color: Colors.green);

    MapLayer polygonsLayer =
        MapLayer(dataSource: polygons, hoverTheme: hoverTheme);

    MapLayer pointsLayer = MapLayer(
        dataSource: points,
        theme: MapTheme(
            color: Colors.black,
            markerBuilder: CircleMakerBuilder(
                key: 'AN', radiuses: {41: 25, 22: 20, 14: 10, 10: 10})),
        hoverTheme: hoverTheme);

    VectorMap map = VectorMap(layers: [polygonsLayer, pointsLayer]);
    return map;
  }
}
