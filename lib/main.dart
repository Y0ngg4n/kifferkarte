import 'package:flutter/material.dart';
import 'package:kifferkarte/map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:kifferkarte/rules.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Kifferkarte());
}

class Kifferkarte extends StatelessWidget {
  Kifferkarte({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        child: MaterialApp(
      title: 'Kifferkarte (Beta)',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: KifferkarteWidget(title: 'Kifferkarte'),
    ));
  }
}

class KifferkarteWidget extends ConsumerStatefulWidget {
  KifferkarteWidget({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  ConsumerState<KifferkarteWidget> createState() => _KifferkarteWidgetState();
}

class _KifferkarteWidgetState extends ConsumerState<KifferkarteWidget> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather

    // than having to individually change instances of widgets.

    bool inWay = ref.watch(inWayProvider);
    bool inCircle = ref.watch(inCircleProvider);
    bool updating = ref.watch(updatingProvider);
    bool smokeable = false;
    DateTime now = DateTime.now();
    if ((!inCircle && !inWay) ||
        (!inCircle && (now.hour < 7 || now.hour >= 20))) {
      smokeable = true;
    }
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          updating
              ? CircularProgressIndicator()
              : smokeable
                  ? Text("Kiffen vermutlich erlaubt")
                  : Text("Kiffen nicht erlaubt"),
          if (!updating)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(smokeable ? Icons.smoking_rooms : Icons.smoke_free),
            )
        ],
      ),
      bottomSheet: SingleChildScrollView(
        child: ExpansionTile(
          title: Text("Gesetzliche Lage und Anwendung"),
          children: [Rules()],
        ),
      ),
      body: MapWidget(),
    );
  }
}
