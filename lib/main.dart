import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kifferkarte/map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:kifferkarte/rules.dart';

/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';
const String taskChannel = "pro.obco.kifferkarte/zone";
final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');
  // final DarwinInitializationSettings initializationSettingsDarwin =
  //     DarwinInitializationSettings(
  //         onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  // final LinuxInitializationSettings initializationSettingsLinux =
  //     LinuxInitializationSettings(defaultActionName: 'Open notification');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  // iOS: initializationSettingsDarwin,
  // macOS: initializationSettingsDarwin,);
  // linux: initializationSettingsLinux);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
    switch (notificationResponse.notificationResponseType) {
      case NotificationResponseType.selectedNotification:
        selectNotificationStream.add(notificationResponse.payload);
        break;
      case NotificationResponseType.selectedNotificationAction:
        if (notificationResponse.actionId == navigationActionId) {
          selectNotificationStream.add(notificationResponse.payload);
        }
        break;
    }
  });
  runApp(Kifferkarte());
}

class Kifferkarte extends StatelessWidget {
  Kifferkarte({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    var android =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    android?.requestNotificationsPermission();
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
      home: KifferkarteWidget(
        title: 'Kifferkarte (Beta)',
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      ),
    ));
  }
}

class KifferkarteWidget extends ConsumerStatefulWidget {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  KifferkarteWidget(
      {super.key,
      required this.title,
      required this.flutterLocalNotificationsPlugin});

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
  bool lastSmokeable = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      showSmokingNotification(lastSmokeable);
    });
  }

  void showSmokingNotification(bool smokeable) {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      taskChannel,
      taskChannel,
      icon: smokeable ? 'ic_stat_smoking_rooms' : 'ic_stat_smoke_free',
      channelDescription: "Kifferkarte Zone Notification",
      actions: [],
    );
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    widget.flutterLocalNotificationsPlugin.cancel(1);
    if (smokeable) {
      widget.flutterLocalNotificationsPlugin.show(
          1,
          "Du kannst vermutlich hier kiffen",
          "Du befindest dich gerade in keiner Zone",
          notificationDetails);
    } else {
      widget.flutterLocalNotificationsPlugin.show(1, "Kiffen verboten",
          "Du solltest hier nicht kiffen", notificationDetails);
    }
  }

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
      widget.flutterLocalNotificationsPlugin.cancel(1);
    }
    if (smokeable != lastSmokeable) {
      showSmokingNotification(smokeable);
      setState(() {
        lastSmokeable = smokeable;
      });
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
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              : smokeable
                  ? Text("Kiffen vermutlich erlaubt")
                  : Text(
                      "Kiffen nicht erlaubt",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
          if (!updating)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(smokeable ? Icons.smoking_rooms : Icons.smoke_free,
                  color: smokeable ? Colors.black : Colors.red),
            )
        ],
      ),
      bottomSheet: SingleChildScrollView(
        child: ExpansionTile(
          title: Text("Gesetzliche Lage und Anwendung"),
          children: [Rules()],
        ),
      ),
      body: MapWidget(
        flutterLocalNotificationsPlugin: widget.flutterLocalNotificationsPlugin,
      ),
    );
  }
}
