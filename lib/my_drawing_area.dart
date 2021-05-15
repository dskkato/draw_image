import 'package:flutter/material.dart';
import 'drawing_area.dart';

class MyDrawingArea extends InheritedWidget {
  final List<DrawingArea> areas = [];
  MyDrawingArea({
    Key? key,
    @required Widget? child,
  })  : assert(child != null),
        super(key: key, child: child!);

  static List<DrawingArea> of(BuildContext context) {
    final List<DrawingArea>? result =
        context.dependOnInheritedWidgetOfExactType<MyDrawingArea>()?.areas;
    assert(result != null, 'No FrogColor found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(MyDrawingArea old) => false;
}
