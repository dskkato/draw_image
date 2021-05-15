import 'package:flutter/material.dart' show Offset, Paint;

class DrawingArea {
  List<Offset> points = [];
  Paint paint;
  bool isClose = false;

  get length => points.length;

  DrawingArea(this.paint);
}
