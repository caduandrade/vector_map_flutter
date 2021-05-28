import 'package:demo/main.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:vector_map/vector_map.dart';

import 'menu.dart';

class DataSources {
  DataSources({this.polygons, this.points});

  final MapDataSource? polygons;
  final MapDataSource? points;
}

abstract class ExamplePageState extends State<StatefulWidget> {
  late List<MenuItem> _menuItems;
  ContentBuilder? _currentBuilder;

  late MultiSplitViewController _horizontalController;
  late MultiSplitViewController _verticalController;

  DataSources? _dataSources;

  @override
  void initState() {
    super.initState();
    _horizontalController = MultiSplitViewController(weights: [.1, .8, .1]);
    _verticalController = MultiSplitViewController(weights: [.1, .8, .1]);
    _menuItems = buildMenuItems();
    if (_menuItems.isNotEmpty) {
      _currentBuilder = _menuItems.first.builder;
    }
    VectorMapDemoPageState? state =
        context.findAncestorStateOfType<VectorMapDemoPageState>();
    if (state != null) {
      String polygonsGeoJSON = state.polygons!;
      String pointsGeoJSON = state.points!;

      loadDataSources(polygonsGeoJSON, pointsGeoJSON).then((value) {
        setState(() {
          _dataSources = value;
        });
      });
    } else {
      throw StateError('VectorMapDemoPageState should not be null');
    }
  }

  Future<DataSources> loadDataSources(
      String polygonsGeoJSON, String pointsGeoJSON);

  _updateContentBuilder(ContentBuilder contentBuilder) {
    setState(() {
      _currentBuilder = contentBuilder;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (_dataSources != null) {
      content = buildContent();
    }
    Scaffold scaffold =
        Scaffold(key: UniqueKey(), body: Center(child: content));

    MaterialApp materialApp = MaterialApp(
        theme: buildThemeData(),
        debugShowCheckedModeBanner: false,
        home: scaffold);

    MultiSplitView horizontal = MultiSplitView(
        dividerThickness: 20,
        children: [_buildEmptyArea(), materialApp, _buildEmptyArea()],
        minimalWeight: .1,
        controller: _horizontalController);

    MultiSplitView vertical = MultiSplitView(
        axis: Axis.vertical,
        dividerThickness: 20,
        children: [_buildEmptyArea(), horizontal, _buildEmptyArea()],
        minimalWeight: .1,
        controller: _verticalController);

    SizedBox sizedBox = SizedBox(child: vertical, width: 591, height: 350);
    Center center = Center(child: sizedBox);

    Widget contentMenu = Container(
      child: MenuWidget(
          contentBuilderUpdater: _updateContentBuilder, menuItems: _menuItems),
      padding: EdgeInsets.all(8),
      decoration:
          BoxDecoration(border: Border(left: BorderSide(color: Colors.blue))),
    );

    Row row = Row(children: [Expanded(child: center), contentMenu]);
    return Container(child: row, color: Colors.white);
  }

  Widget _buildEmptyArea() {
    return Container(color: Colors.white);
  }

  ThemeData? buildThemeData() {
    return ThemeData(scaffoldBackgroundColor: Colors.white);
  }

  List<MenuItem> buildMenuItems() {
    return [];
  }

  MapDataSource get polygons {
    return _dataSources!.polygons!;
  }

  MapDataSource get points {
    return _dataSources!.points!;
  }

  Widget buildContent() {
    if (_currentBuilder != null) {
      return _currentBuilder!();
    }
    return Center();
  }
}
