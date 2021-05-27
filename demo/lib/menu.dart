import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef ContentBuilder = Widget Function();

typedef ContentBuilderUpdater = Function(ContentBuilder contentBuilder);

class MenuItem {
  MenuItem(this.name, this.builder);

  final String name;
  final ContentBuilder builder;
}

class MenuWidget extends StatelessWidget {
  const MenuWidget(
      {Key? key, required this.contentBuilderUpdater, required this.menuItems})
      : super(key: key);

  final ContentBuilderUpdater contentBuilderUpdater;
  final List<MenuItem> menuItems;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (MenuItem menuItem in menuItems) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: 8));
      }
      children.add(_buildButton(menuItem));
    }
    return SingleChildScrollView(child: Column(children: children));
  }

  ElevatedButton _buildButton(MenuItem menuItem) {
    return ElevatedButton(
        onPressed: () => contentBuilderUpdater(menuItem.builder),
        child: Text(menuItem.name));
  }
}
