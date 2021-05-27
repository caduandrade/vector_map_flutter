import 'dart:convert';

import 'package:demo/click_listener_page.dart';
import 'package:demo/color_by_rule_page.dart';
import 'package:demo/color_by_value_page.dart';
import 'package:demo/contour_page.dart';
import 'package:demo/default_colors_page.dart';
import 'package:demo/enable_hover_by_value_page.dart';
import 'package:demo/get_started_page.dart';
import 'package:demo/gradient_page.dart';
import 'package:demo/hover_page.dart';
import 'package:demo/label_page.dart';
import 'package:demo/menu.dart';
import 'package:demo/parser_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(VectorMapDemoApp());
}

class VectorMapDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vector Map Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapChartDemoPage(),
    );
  }
}

class MapChartDemoPage extends StatefulWidget {
  @override
  MapChartDemoPageState createState() => MapChartDemoPageState();
}

class MapChartDemoPageState extends State<MapChartDemoPage> {
  late List<MenuItem> _menuItems;
  ContentBuilder? _currentExampleBuilder;
  String? geojson;

  @override
  void initState() {
    super.initState();
    _menuItems = [
      MenuItem('Get Started', _getStartedPage),
      MenuItem('Default colors', _defaultColorsPage),
      MenuItem('Color by value', _colorByValuePage),
      MenuItem('Contour', _contourPage),
      MenuItem('Enable hover by value', _enableHoverByValuePage),
      MenuItem('Click listener', _clickListenerPage),
      MenuItem('Color by rule', _colorByRulePage),
      MenuItem('Gradient', _gradientPage),
      MenuItem('Parser', _parserPage),
      MenuItem('Hover', _hoverPage),
      MenuItem('Label', _labelPage)
    ];
    if (_menuItems.isNotEmpty) {
      _currentExampleBuilder = _menuItems.first.builder;
    }
    rootBundle.loadString('assets/example.json').then((json) {
      // _printProperties(json);
      setState(() {
        geojson = json;
      });
    });
  }

  _printProperties(String geojson) async {
    print('Name | Seq | Rnd');
    print('--- | --- | ---');
    Map<String, dynamic> map = await json.decode(geojson);
    List features = map['features']!;
    for (Map<String, dynamic> feature in features) {
      Map<String, dynamic> properties = feature['properties'];
      String name = properties['Name'];
      int seq = properties['Seq'];
      String rnd = '';
      if (properties.containsKey('Rnd')) {
        rnd = properties['Rnd'];
        rnd = '"$rnd"';
      }
      print('"$name" | $seq | $rnd');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget exampleMenu = Container(
      child: MenuWidget(
          contentBuilderUpdater: _updateExampleContentBuilder,
          menuItems: _menuItems),
      padding: EdgeInsets.all(8),
      decoration:
          BoxDecoration(border: Border(right: BorderSide(color: Colors.blue))),
    );

    Widget? body;
    if (geojson == null) {
      body = Center(child: Text('Loading...'));
    } else {
      body = Row(
          children: [exampleMenu, Expanded(child: _buildExample())],
          crossAxisAlignment: CrossAxisAlignment.stretch);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('MapChart Demo'),
        ),
        body: body);
  }

  _updateExampleContentBuilder(ContentBuilder contentBuilder) {
    setState(() {
      _currentExampleBuilder = contentBuilder;
    });
  }

  Widget _buildExample() {
    if (_currentExampleBuilder != null) {
      return _currentExampleBuilder!();
    }
    return Center();
  }

  GetStartedPage _getStartedPage() {
    return GetStartedPage();
  }

  ColorByValuePage _colorByValuePage() {
    return ColorByValuePage();
  }

  DefaultColorsPage _defaultColorsPage() {
    return DefaultColorsPage();
  }

  ContourPage _contourPage() {
    return ContourPage();
  }

  EnableHoverByValuePage _enableHoverByValuePage() {
    return EnableHoverByValuePage();
  }

  ClickListenerPage _clickListenerPage() {
    return ClickListenerPage();
  }

  ColorByRulePage _colorByRulePage() {
    return ColorByRulePage();
  }

  GradientPage _gradientPage() {
    return GradientPage();
  }

  ParserPage _parserPage() {
    return ParserPage();
  }

  HoverPage _hoverPage() {
    return HoverPage();
  }

  LabelPage _labelPage() {
    return LabelPage();
  }
}
