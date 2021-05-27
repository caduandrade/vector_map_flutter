import 'package:demo/main.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:vector_map/vector_map.dart';

import 'menu.dart';

abstract class ExamplePageState extends State<StatefulWidget> {
  late List<MenuItem> _menuItems;
  ContentBuilder? _currentBuilder;

  late MultiSplitViewController _horizontalController;
  late MultiSplitViewController _verticalController;

  late String geojson;

  VectorMapDataSource? dataSource;

  @override
  void initState() {
    super.initState();
    _horizontalController = MultiSplitViewController(weights: [.1, .8, .1]);
    _verticalController = MultiSplitViewController(weights: [.1, .8, .1]);
    _menuItems = buildMenuItems();
    if (_menuItems.isNotEmpty) {
      _currentBuilder = _menuItems.first.builder;
    }
    MapChartDemoPageState? state =
        context.findAncestorStateOfType<MapChartDemoPageState>();
    geojson = state!.geojson!;

    loadDataSource(geojson).then((value) {
      setState(() {
        dataSource = value;
      });
    });
  }

  Future<VectorMapDataSource> loadDataSource(String geojson);

  _updateContentBuilder(ContentBuilder contentBuilder) {
    setState(() {
      _currentBuilder = contentBuilder;
    });
  }

  @override
  Widget build(BuildContext context) {
    Scaffold scaffold =
        Scaffold(key: UniqueKey(), body: Center(child: buildContent()));

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

  Widget buildContent() {
    if (_currentBuilder != null) {
      return _currentBuilder!();
    }
    return Center();
  }
}
