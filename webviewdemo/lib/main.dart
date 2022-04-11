  import 'package:flutter/material.dart';
  import 'package:webview_flutter/webview_flutter.dart';
  import 'dart:async';
  import 'package:flutter_local_notifications/flutter_local_notifications.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'firebase_options.dart';
  import 'package:firebase_messaging/firebase_messaging.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    print('____________________User granted permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('___________________Message data: ${message.data}');


    if (message.notification != null) {
      print('_________________Message also contained a notification: ${message.notification}');
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Home', url: 'http://site.motorland.by/mobileapp/?i=3'),
    );
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewController _controller;
  late String testVar = '';

  final Completer<WebViewController> _controllerCompleter =
      Completer<WebViewController>();
  //Make sure this function return Future<bool> otherwise you will get an error
  Future<bool> _onWillPop(BuildContext context) async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }

  late FlutterLocalNotificationsPlugin localNotification;

  Future<void> saveTokenToDatabase(String token) async {
  // Assume user is logged in for this example
  print('___________________TOKEN: $token');
  testVar = token;
}

  late String _token;

  Future<void> setupToken(String appId) async {
    // Get the token each time the application loads
    String? token = await FirebaseMessaging.instance.getToken(vapidKey: appId);

    // Save the initial token to the database
    await saveTokenToDatabase(token!);

    // Any time the token refreshes, store this in the database too.
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);


  }

  @override
  void initState() {
    super.initState();



    localNotification = FlutterLocalNotificationsPlugin();
    var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var ios = const IOSInitializationSettings();
    var initSetttings = InitializationSettings(android: android, iOS: ios);
    localNotification.initialize(initSetttings);
  }
  Future _showNotification(String message) async{
    var androidDetails = const AndroidNotificationDetails(
      'channel id',
      'channel NAME',
      channelDescription: 'channelDescription',
      importance: Importance.high
    );
    var iosDetails = const IOSNotificationDetails();
    var platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await localNotification.show(0, 'Message from web view', message, platformDetails);
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(testVar),
        ),
        body: SafeArea(
            child: WebView(
              key: UniqueKey(),
              onWebViewCreated: (WebViewController webViewController) {
                _controllerCompleter.future.then((value) => _controller = value);
                _controllerCompleter.complete(webViewController);
              },
              javascriptMode: JavascriptMode.unrestricted,
              initialUrl: widget.url,
              javascriptChannels: <JavascriptChannel>{
                JavascriptChannel(
                  name: 'messageHandler',
                  onMessageReceived: (JavascriptMessage message) {
                    Timer(const Duration(seconds: 3), () {
                      _showNotification(message.message);
                      setupToken(message.message);
                    });
                  },
              )
          },
        )),
      ),
    );
  }
}