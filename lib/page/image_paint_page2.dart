import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:quiver/iterables.dart' show cycle;
import '../drawing_area.dart';
import '../my_drawing_area.dart';

class ImagePaintPage2 extends StatefulWidget {
  @override
  _ImagePaintPageState createState() => _ImagePaintPageState();
}

class _ImagePaintPageState extends State<ImagePaintPage2> {
  List<DrawingArea>? areas;
  final _minDistance = 3.0;
  bool _isDrawing = false;

  static List<Color> _colors = [
    Color.fromARGB(128, 255, 0, 0),
    Color.fromARGB(128, 0, 255, 0),
    Color.fromARGB(128, 0, 0, 255),
  ];
  Iterator<Paint> _closePaints = cycle(List<Paint>.generate(
      _colors.length,
      (index) => Paint()
        ..color = _colors[index]
        ..style = PaintingStyle.fill
        ..strokeWidth = 0.0)).iterator
    ..moveNext();
  Iterator<Paint> _openPaints = cycle(List<Paint>.generate(
      _colors.length,
      (index) => Paint()
        ..color = _colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0)).iterator
    ..moveNext();

  final Image image = Image.asset(
    'assets/fruit.jpg',
  );

  @override
  build(context) {
    areas = MyDrawingArea.of(context);
    return Center(
      child: GestureDetector(
        onPanUpdate: (details) {
          var point = details.localPosition;
          if (_isDrawing) {
            final points = areas!.last.points;
            final startPoint = points.first;
            if (points.length > 10 &&
                (point - startPoint).distance < _minDistance) {
              // close the path
              setState(() {
                areas!.last.points.add(point);
                areas!.last.isClose = true;
                areas!.last.paint = _closePaints.current;
                _closePaints.moveNext();
                _isDrawing = false;
              });
            } else {
              // update the path
              setState(() {
                areas!.last.points.add(point);
              });
            }
          }
        },
        onPanStart: (details) {
          var point = details.localPosition;
          if (_isDrawing) {
            final points = areas!.last.points;
            final startPoint = points.first;
            if ((point - startPoint).distance < _minDistance) {
              // close the path
              setState(() {
                areas!.last.points.add(point);
                areas!.last.isClose = true;
                areas!.last.paint = _closePaints.current;
                _closePaints.moveNext();
                _isDrawing = false;
              });
            } else {
              // update the path
              setState(() {
                areas!.last.points.add(point);
              });
            }
          } else {
            // start a path
            final area = DrawingArea(_openPaints.current);
            area.points.add(point);

            setState(() {
              areas!.add(area);
              _openPaints.moveNext();
              _isDrawing = true;
            });
          }
        },
        child: ClipRect(
          child: Stack(
            children: [
              image,
              CustomPaint(
                painter: DrawingPainter(areas!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingArea> areas;
  DrawingPainter(this.areas);

  @override
  void paint(Canvas canvas, Size size) {
    for (var area in areas) {
      final points = area.points;
      final paint = area.paint;
      if (area.isClose && points.length > 0) {
        var path = Path();

        var it = points.iterator..moveNext();
        path.moveTo(it.current.dx, it.current.dy);
        while (it.moveNext()) {
          path.lineTo(it.current.dx, it.current.dy);
        }
        canvas.drawPath(path, paint);
      } else {
        canvas.drawPoints(ui.PointMode.polygon, points, paint);
        canvas.drawCircle(points.first, 3, Paint()..color = Colors.black);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter old) {
    return old.areas == areas;
  }
}
