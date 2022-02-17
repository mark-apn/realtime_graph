import 'package:flutter/material.dart';
import 'package:realtime_graph/realtime_graph.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = RealtimeGraphController();

  int _recentCounts = 0;

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      setState(() {
        _recentCounts = controller.dataPoints.length;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button',
            ),
            Text(
              '$_recentCounts',
              style: Theme.of(context).textTheme.headline4,
            ),
            const Text(
              'times in the last 10 seconds',
            ),
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              child: RealtimeGraph(controller: controller),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.addDataPoint,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
