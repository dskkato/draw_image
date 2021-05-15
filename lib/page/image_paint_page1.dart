import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'dart:io'; //　File
import 'dart:typed_data'; // Uint8List
import 'package:quiver/iterables.dart' show cycle;
import '../drawing_area.dart';
import '../my_drawing_area.dart';

class ImagePaintPage1 extends StatefulWidget {
  @override
  _ImagePaintPageState createState() => _ImagePaintPageState();
}

class _ImagePaintPageState extends State<ImagePaintPage1> {
  ui.Image? image;
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

  @override
  void initState() {
    super.initState();

    loadImage('assets/fruit.jpg');
  }

  Future loadImage(String path) async {
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    final image = await decodeImageFromList(bytes);

    setState(() {
      this.image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    areas = MyDrawingArea.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Center(
          child: image == null
              ? CircularProgressIndicator()
              : GestureDetector(
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
                  child: Container(
                    child: FittedBox(
                      child: SizedBox(
                        width: image!.width.toDouble(),
                        height: image!.height.toDouble(),
                        child: ClipRect(
                          child: CustomPaint(
                            painter: ImagePainter(image!, areas!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        ElevatedButton(
          onPressed: () async {
            print("onPressed");
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            var painter = ImagePainter(image!, areas!);
            var size = Size(image!.width.toDouble(), image!.height.toDouble());
            painter.paint(canvas, size);
            final picture = recorder.endRecording();
            final img = await picture.toImage(image!.width, image!.height);
            final buf = await img.toByteData(format: ui.ImageByteFormat.png);
            print(buf);
            _requestPermission();
            final result = await ImageGallerySaver.saveImage(
              Uint8List.view(buf!.buffer),
              name: "hello",
            );
            print(result);
          },
          child: Text('Save'),
        ),
      ],
    );
  }

  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    final info = statuses[Permission.storage].toString();
    print(info);
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<DrawingArea> areas;

  const ImagePainter(this.image, this.areas);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);

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
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
