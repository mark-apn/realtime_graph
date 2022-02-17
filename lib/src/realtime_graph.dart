import 'package:flutter/material.dart';

class RealtimeGraphController {
  final listeners = <VoidCallback>[];
  final dataPoints = <DateTime>[];

  void addDataPoint() {
    dataPoints.add(DateTime.now());
    _updateListeners();
  }

  void removeDataPoint() {
    dataPoints.removeLast();
    _updateListeners();
  }

  void _updateListeners() {
    for (var listener in listeners) {
      Future.microtask(listener);
    }
  }

  void addListener(VoidCallback listener) {
    listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
  }

  void dispose() {
    listeners.clear();
  }

  void removeOlderThan(Duration visibleTimeFrame) {
    final oldLength = dataPoints.length;

    final now = DateTime.now();
    dataPoints.removeWhere((element) {
      final timeDiff = now.difference(element).inMilliseconds;
      return timeDiff > visibleTimeFrame.inMilliseconds;
    });

    final newLength = dataPoints.length;

    if (newLength != oldLength) {
      _updateListeners();
    }
  }
}

class RealtimeGraph extends StatefulWidget {
  const RealtimeGraph({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final RealtimeGraphController controller;

  @override
  State<RealtimeGraph> createState() => _RealtimeGraphState();
}

class _RealtimeGraphState extends State<RealtimeGraph> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // To calculate stable rolling time for the gridlines
  final startTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RealtimeGraphPainter(
        listenable: _controller,
        controller: widget.controller,
        startTime: startTime,
        visibleTimeFrame: const Duration(seconds: 10),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class RealtimeGraphPainter extends CustomPainter {
  final painter = Paint()
    ..color = Colors.blue
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  final gridPainter = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.fill;

  final Animation listenable;
  final RealtimeGraphController controller;
  final Duration visibleTimeFrame;
  final DateTime startTime;

  double gridOffset = 0;
  num maxY = 0;
  Map<int, int> points = {};
  List<double> lines = [];

  RealtimeGraphPainter({
    required this.controller,
    required this.visibleTimeFrame,
    required this.startTime,
    required this.listenable,
  }) : super(repaint: listenable);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, painter);

    _updateGridOffset();
    _updatePoints();

    //paint grid lines (10 lines)
    for (var i = 1; i < 11; i++) {
      final width = size.width / 10;
      final line = i * width;
      final offset = line - (gridOffset * width);
      canvas.drawLine(Offset(offset, 0), Offset(offset, size.height), gridPainter);

      if (points.containsKey(i)) {
        canvas.drawCircle(
          Offset(offset, size.height - ((size.height / (maxY+1)) * points[i]!)),
          2.0,
          gridPainter,
        );
      } else {
          canvas.drawCircle(
          Offset(offset, size.height),
          2.0,
          gridPainter,
        );
      }
    }
  }

  void _updatePoints() {
    final now = DateTime.now();

    // get the points from the controller
    // process the points to get the x and y values
    points.clear();
    for (var point in controller.dataPoints) {
      final millisecondsPerLine = visibleTimeFrame.inMilliseconds / 10;
      final timeDiff = now.difference(point).inMilliseconds;
      final diffWithGridCorrection = timeDiff - (gridOffset * millisecondsPerLine);

      final bucket = 10 - (diffWithGridCorrection / millisecondsPerLine).floor();

      final bucketSize = (points[bucket] ?? 0) + 1;

      if(bucketSize > maxY) {
        maxY = bucketSize;
      }

      points[bucket] = bucketSize;
    }

    // remove points outside the visible area
    controller.removeOlderThan(visibleTimeFrame + const Duration(seconds: 1));
  }

  void _updateGridOffset() {
    // add 10 lines to the grid
    final now = DateTime.now();
    final millisecondsPerLine = visibleTimeFrame.inMilliseconds / 10;
    gridOffset = (now.difference(startTime).inMilliseconds % millisecondsPerLine) / millisecondsPerLine;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; //This realtime graph is always repainting
  }
}
