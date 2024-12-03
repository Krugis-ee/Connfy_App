import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Implement this service to show notifications

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    registerForNotifications();
  }

  Future<void> registerForNotifications() async {
    messaging = FirebaseMessaging.instance;

    // Request permissions for iOS (does not affect Android)
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get the token for the device
    final fcmToken = await messaging.getToken();
    print(fcmToken);

    // Subscribe to a topic
    await messaging.subscribeToTopic('flutter_notification');

    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'flutter_notification', // id
        'flutter_notification_title', // title
        importance: Importance.high,
        enableLights: true,
        enableVibration: true,
        showBadge: true,
        playSound: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings android = AndroidInitializationSettings('@drawable/ic_notifications_icon');
      const DarwinInitializationSettings iOS = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(android: android, iOS: iOS);

      final initialized = await flutterLocalNotificationsPlugin?.initialize(
        initSettings,
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (initialized == null || !initialized) {
        // Handle the error of initialization
        print("Error: flutterLocalNotificationsPlugin failed to initialize");
        return;
      }

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Handling a foreground message: ${message.messageId}');
        print('Notification Message: ${message.data}');

        final data = message.data;
        final title = data['title'] ?? 'Notification Title';
        final body = data['body'] ?? 'Notification Body';

        // NotificationService().showNotification(title: title, body: body);
      });
    }
  }

  void notificationTapBackground(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped in background');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FCM Notification Example'),
      ),
      body: Center(
        child: Text('Awaiting notifications...'),
      ),
    );
  }
}
/*
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Chat'),
    ),
    body: Stack(
      children: [
        StreamBuilder(
          stream: chats,
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isScrolledUp) {
                scrollToBottom_(); // Auto-scroll only if user hasn't scrolled up
              }
            });

            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              controller: _scrollController,
              shrinkWrap: true,
              reverse: false, // Set reverse to false for ascending order
              itemBuilder: (context, index) {
                // Sort the messages by timestamp in ascending order
                var sortedMessages = snapshot.data!.docs..sort((a, b) {
                  Timestamp timeA = a['time'];
                  Timestamp timeB = b['time'];
                  return timeA.compareTo(timeB); // Ascending order
                });

                var messageData = sortedMessages[index];
                if (messageData == null) {
                  return const SizedBox.shrink();
                }

                String? messageId = messageData.id;
                String message = messageData["message"];
                bool sendByMe = Constants.myName == messageData["sendBy"];
                Timestamp time = messageData["time"];
                bool isRead = messageData["read"];
                bool isDelivered = messageData["delivered"];
                bool isSent = messageData["sent"];

                return Messages(
                  message: message,
                  sendByMe: sendByMe,
                  time: time,
                  imageurl: imageurl,
                  isRead: isRead,
                  isDelivered: isDelivered,
                  isSent: isSent,
                  chatRoomId: chatRoomId,
                  messageID: messageId,
                );
              },
            );
          },
        ),
        if (_isScrolledUp)
          Positioned(
            bottom: 80,
            right: 10,
            child: FloatingActionButton(
              onPressed: scrollToBottom_,
              child: const Icon(Icons.arrow_downward),
            ),
          ),
        Positioned(
          bottom: 100,
          right: 50,
          child: FloatingActionButton(
            onPressed: scrollToBottom_,
            child: const Icon(Icons.arrow_downward),
          ),
        ),
      ],
    ),
  );
}*/
