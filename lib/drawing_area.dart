import 'package:flutter/material.dart';

class DrawingArea {
  List<Offset> points = [];
  Paint paint;
  bool isClose = false;

  get length => points.length;

  DrawingArea(this.paint);
}
