import 'dart:async';
import 'dart:convert';

import 'package:chatapp/constant.dart';
import 'package:chatapp/helper/constants.dart';
import 'package:chatapp/screens/profile.dart';
import 'package:chatapp/screens/socialmatch.dart';
import 'package:chatapp/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../AppColorCodes.dart';
import '../controller/Constant.dart';
import '../main.dart';
import 'ChatProvider.dart';
import 'NetworkService.dart';
import 'chatlistnew.dart';

class Chat extends StatefulWidget {
  final chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token;

  Chat(this.chatRoomId, this.uid, this.username, this.routeid, this.user_id, this.imageurl, this.senderid, this.token);

  @override
  _ChatState createState() => _ChatState(this.chatRoomId, this.uid, this.username, this.routeid, this.user_id, this.imageurl, this.senderid, this.token);
}

class _ChatState extends State<Chat> {
  var chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token;
  _ChatState(this.chatRoomId, this.uid, this.username, this.routeid, this.user_id, this.imageurl, this.senderid, this.token);
  Stream<QuerySnapshot>? chats;
  int wifi_sttus = -1;
  String statuslable = "";
  dynamic colorcodelable;
  List<String> supplier_typelist = ["NEW REQUESTS", 'OLD REQUESTS'];
  Timer? _timer;
  String _connectionStatus = 'Unknown';
  String globalTime = "";
  late ConnectivityResult result;
  StreamController<bool> _streamController = StreamController<bool>();
  late StreamSubscription<bool> _streamSubscription;
  final NetworkInfo _networkInfo = NetworkInfo();
  bool _scrollingToBottom = false;
  TextEditingController messageEditingController = TextEditingController();
  String? UserId = "";
  String? loginuser = "";
  //final LocalStorage storage = new LocalStorage('wifi');
  String config_wifi = "emty";
  /* Widget chatMessages() {
    // print(chatRoomId + ">>>>" + uid + '>>>>' + Constants.myName);
    return Container(
      height: double.infinity,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      child: StreamBuilder(
        stream: chats,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              // Scroll to the bottom of the list
              if (snapshot.data!.docs.isNotEmpty) {
                final controller = PrimaryScrollController.of(context);
                if (controller != null) {
                  // Ensure that controller.position is not null before accessing maxScrollExtent
                  if (controller.position != null) {
                    controller.animateTo(
                      controller.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              }
            });

            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                var messageData = snapshot.data?.docs[index];
                if (messageData == null) {
                  return const SizedBox.shrink();
                }

                String? messageId = messageData.id;
                String message = messageData["message"];
                bool sendByMe = Constants.myName == messageData["sendBy"];
                bool isRead = messageData["read"];
                if (sendByMe) {
                  isRead = false;
                } else {
                  DatabaseMethods().updateMessageReadStatus(widget.chatRoomId, messageId);
                  DatabaseMethods().getMessageReadStatus(widget.chatRoomId, messageId).then((val) {
                    isRead = val!;
                  });
                }
                Timestamp time = messageData["time"];

                print("isRead $isRead");
                bool isDelivered = messageData["delivered"];
                print("isDelivered $isDelivered");
                bool isSent = messageData["sent"];
                DateTime dateTime = time.toDate();
                String formattedTime = DateFormat('h:mm a').format(dateTime);
                return
                    */
  /* Messages(
                  message: message,
                  sendByMe: sendByMe,
                  time: time,
                  imageurl: imageurl,
                  isRead: isRead,
                  isDelivered: isDelivered,
                  isSent: isSent,
                  chatRoomId: chatRoomId,
                  messageID: messageId,
                );*/
  /*
                    Padding(
                  padding: const EdgeInsets.only(top: pDefaultPadding * 0.9, left: 5),
                  child: Row(
                    mainAxisAlignment: sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!sendByMe) ...[
                        Container(
                          height: 35,
                          width: 35,
                          child: Image.network(imageurl),
                        )
                      ],
                      const SizedBox(
                        width: pDefaultPadding / 2,
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        child: IntrinsicWidth(
                          child: sendByMe
                              ? Container(
                                  margin: const EdgeInsets.only(top: 0, right: 5),
                                  padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(0),
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          message,
                                          style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
                                        child: Row(
                                          children: [
                                            Text(
                                              formattedTime,
                                              style: GoogleFonts.poppins(
                                                color: Colors.black45,
                                                fontSize: 10,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            isRead
                                                ? const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.blue,
                                                    size: 15,
                                                  )
                                                : const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.grey,
                                                    size: 15,
                                                  ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: sendByMe ? Colors.black26 : pSecondaryColor,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      topLeft: Radius.circular(0),
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          message,
                                          style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        formattedTime,
                                        style: GoogleFonts.poppins(
                                          color: Colors.black45,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }*/

/*  Widget chatMessages() {
    // print(chatRoomId + ">>>>" + uid + '>>>>' + Constants.myName);
    return Container(
      height: double.infinity,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      child: StreamBuilder(
        stream: chats,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              // Scroll to the bottom of the list
              if (snapshot.data!.docs.isNotEmpty) {
                final controller = PrimaryScrollController.of(context);
                if (controller != null) {
                  // Ensure that controller.position is not null before accessing maxScrollExtent
                  if (controller.position != null) {
                    controller.animateTo(
                      controller.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              }
            });



            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                var messageData = snapshot.data?.docs[index];
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
          } else {
            return Container();
          }
        },
      ),
    );
  }*/
 /* void scrollToBottom() {
    if (_scrollController.hasClients && !_scrollingToBottom) {
      _scrollingToBottom = true;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }
*/
  /*Widget chatMessages() {
    // print(chatRoomId + ">>>>" + uid + '>>>>' + Constants.myName);
    return SafeArea(
      //  height: double.infinity,
      // width: MediaQuery.of(context).size.width,
      // padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      child: StreamBuilder(
        stream: chats,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              controller: _scrollController,
              itemBuilder: (context, index) {
                var messageData = snapshot.data?.docs[index];
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
          } else {
            return Container();
          }
        },
      ),
    );
  }*/
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,  // Scroll to the top
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget chatMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Scroll to the end of the ListView
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return SafeArea(
      child:
      StreamBuilder(
        stream: chats,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            // Automatically scroll to the end when new data is loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              }
            });

            return
              ListView.builder(
            reverse: true,
              itemCount: snapshot.data?.docs.length,
              controller: _scrollController,
              itemBuilder: (context, index) {
                var messageData = snapshot.data?.docs[index];
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
          } else {
            return Container();
          }
        },
      ),
    );
  }

  bool readstatus = false;
  void addMessage() {
    if (messageEditingController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "sendBy": Constants.myName,
        "message": messageEditingController.text,
        'time': Timestamp.now(), // Using Firestore Timestamp
        'read': false, // Initial read status is false
        'delivered': false, // Initial delivered status is false
        'sent': true, // Message is initially sent
      };

      // Add message to the database
      DatabaseMethods().addMessage(chatRoomId, chatMessageMap);

      sendPushNotification(token, loginuser!, messageEditingController.text);

      // Update read status for previous messages in the chat room (assuming this is necessary)
      getGlobalTime(messageEditingController.text);

      setState(() {
        messageEditingController.text = "";
      });
    }
  }

  static Future<void> sendPushNotification(String mobile_device_id, String title, String description) async {
    var headers = {
      'Authorization': 'key=AAAAGLDkAjg:APA91bFsO9qoCm-dYTaDicJ9cHDsg8ur4HY-dqx2tRzSJrh1X7Lxg0c0pZrBEfSSnRoOHdAMUMuRe59YnWkKXFMA3BOTw5QLAqhXzUe_MQ6Bsuu71RvxGkJ5l23obQBayyOyLRJzXYk1',
      'Content-Type': 'application/json'
    };
    var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/send_notification'));
    request.body = json.encode({"title": "Message from:" + title, "description": description, "mobile_device_id": mobile_device_id});
    request.headers.addAll(headers);
    print(request.body);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }



  Future<void> addchannel_server() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    print(UserId);
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/channel_create'));
    request.body = json.encode({"user_id": UserId, "request_user_id": user_id, "channel_id": chatRoomId});
    print(json.encode({"user_id": UserId, "request_user_id": user_id, "channel_id": chatRoomId}));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  late FirebaseMessaging messaging;
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

      final bool? initialized = await flutterLocalNotificationsPlugin?.initialize(
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
    }
  }

  void showNotificationDialog(String title, String body, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Set a finite width for the content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl.isNotEmpty)
                  FutureBuilder(
                    future: precacheImage(NetworkImage(imageUrl), context),
                    builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 100, // Placeholder height
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        return Image.network(
                          imageUrl,
                          height: 100, // Adjust height as needed
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                    },
                  ),
                Text(body),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  late ScrollController _scrollController = ScrollController();
  bool _isScrolledUp = false;
/*  @override
  void initState() {
    super.initState();
    retrive();
    registerForNotifications();
   _scrollController = ScrollController();

    addchannel_server();
    print('chatRoomId $chatRoomId');
    // _initConnectivity();
    //  _startTimer();

    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });
      // Once the chat data is loaded, check the scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {


        // If the scroll controller is already at the bottom, hide the scroll button
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
          setState(() {
            _isScrolledUp = false;  // At the bottom, so no button needed
          });
        } else {
          setState(() {
            _isScrolledUp = true;   // Not at the bottom, show button
          });
        }

        // Optionally scroll to the bottom right after loading
        scrollToBottom_();
      });
    });

   // scrollToBottom_();

    // Scroll to the bottom once the data is loaded and the UI is built


  //  scrollToBottom(_scrollController);
    _scrollController.addListener(() {


      if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) {
        // User scrolled up, show the button
        if (!_isScrolledUp) {
          print('_scrollController.position.pixels::${_scrollController.position.pixels}:::${_scrollController.position.maxScrollExtent}');
          setState(() {
            _isScrolledUp = true;
          });
        }
      } else {
        // User is at the bottom, hide the button
        if (_isScrolledUp) {
          setState(() {
            _isScrolledUp = false;
          });
        }
      }
    });
    scrollToBottom(_scrollController);
    //  _markMessagesAsRead();
  }*/
  late final ScrollController scrollController;

  /// 画面の何割をスクロールした時点で次の _limit 件のメッセージを取得するか。
  static const _scrollValueThreshold = 0.8;
  @override
  void initState() {
    super.initState();

    retrive();
   // registerForNotifications();

   // _scrollController = ScrollController(initialScrollOffset: 50.0);

    addchannel_server();
    print('chatRoomId $chatRoomId');
    scrollController = ScrollController(onAttach: (position) {
      var chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.scrollToBottom(scrollController);
    });
    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });
      for (int i = 0; i < 12; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }

      // Use a delayed scroll to ensure the UI is fully built before scrolling
     WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {

            //scrollToBottom_();

        });
      });
    });

    // Listener for scrolling
  /*  _scrollController.addListener(() {
      if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) {
        // User scrolled up, show the button
        if (!_isScrolledUp) {
          setState(() {
            _isScrolledUp = true;
          });
        }
      } else {
        // User is at the bottom, hide the button
        if (_isScrolledUp) {
          setState(() {
            _isScrolledUp = false;
          });
        }
      }
    });*/
  }

// Scroll to bottom method
  bool _isScrolling = false;

  void scrollToBottom_() {
    for (int i = 0; i < 12; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }

    _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut);

  }


  void scrollToBottom(ScrollController scrollController) {


    if (scrollController.hasClients) {

      for (int i = 0; i < 12; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });
      }
    }
    else{
      print("gdfgfgfg fgfhfhhh");
    }
  }

 /* void scrollToBottom_() {
   _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }*/
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await Future.delayed(Duration(seconds: 3));

    var snapshot = await FirebaseFirestore.instance.collection("chatRoom").doc(widget.chatRoomId).collection("chats").where("read", isEqualTo: false).get();

    for (var doc in snapshot.docs) {
      await updateMessageReadStatus(widget.chatRoomId, doc.id);
    }
    if (mounted && !readstatus) {
      _markMessagesAsRead();
    }
  }

  Future<void> updateMessageReadStatus(String chatRoomId, String messageId) async {
    try {
      await FirebaseFirestore.instance.collection("chatRoom").doc(chatRoomId).collection("chats").doc(messageId).update({'read': true});
    } catch (e) {
      print('Failed to update message read status: ${e.toString()}');
    }
  }

  Future retrive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    loginuser = prefs.getString('loginuser');
    // await storage.ready;
    String? name = localStorage.getItem('wifiname');
    String? ssid = localStorage.getItem('SSID');
    config_wifi = localStorage.getItem('wifiname')!;
    // _initNetworkInfo();

    // _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => _initNetworkInfo());
  }

  Future<String?> getGlobalTime(String msg) async {
    try {
      // Make a GET request to the World Time API
      var response = await http.get(Uri.parse('https://worldtimeapi.org/api/ip'));

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response JSON
        Map<String, dynamic> data = jsonDecode(response.body);

        // Extract the global time from the response
        globalTime = data['datetime'];
        addmessage_server(msg, globalTime);

        return globalTime;
      } else {
        addmessage_server(msg, "");
        print('Failed to fetch global time: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      addmessage_server(msg, "");
      print('Error fetching global time: $e');
      return null;
    }
  }

  AppBar buildAppBar() {
    bool isConnectedToConfiguredWifi = Provider.of<NetworkService>(context).wifiName.toString().replaceAll('"', '') == config_wifi;
    return AppBar(
      backgroundColor: const Color(0xff03A0E3),
      titleSpacing: 0,
      title: Row(
        children: [
          GestureDetector(
            child: Stack(
              children: [
                Image.network(
                  imageurl,
                  fit: BoxFit.contain,
                  height: 45,
                ),
                isConnectedToConfiguredWifi == true
                    ? Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: Color(0xff03A0E3), shape: BoxShape.circle),
                        ),
                      )
                    : Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      )
              ],
            ),
            onTap: () {},
          ),
          const SizedBox(
            width: pDefaultPadding * 0.7,
          ),
          Container(
            width: MediaQuery.of(context).size.width / 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(
                  height: 1,
                ),
                Opacity(
                    opacity: 0.9,
                    child: isConnectedToConfiguredWifi == true
                        ? const Text('online', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white))
                        : const Text('Offline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.red)))
              ],
            ),
          )
        ],
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
        ),
        onPressed: () {
          //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList(uid)));
          if (routeid == '1') {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatListnew("1")));
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList("2")));
          }
        },
      ),
      actions: [
        PopupMenuButton(
            color: Colors.white,
            iconColor: Colors.white,
            // add icon, by default "3 dot" icon
            // icon: Icon(Icons.book)
            itemBuilder: (context) {
              return [
                const PopupMenuItem<int>(
                  value: 0,
                  child: Text("Profile", style: TextStyle(color: Colors.blue)),
                ),
              ];
            },
            onSelected: (value) {
              if (value == 0) {
                if (isConnectedToConfiguredWifi == true) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfilePage(chatRoomId, uid, username, routeid, user_id, imageurl, token)));
                }
              } else if (value == 1) {
                print("Settings menu is selected.");
              } else if (value == 2) {
                print("Logout menu is selected.");
              }
            }),
      ],
    );
  }


  bool _isNearBottom() {
    if (!_scrollController.hasClients) return false;
    final threshold = 200.0; // Set a threshold distance
    return _scrollController.position.extentAfter < threshold;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(),
      body: Consumer<ChatProvider>(builder: (_, chatProvider, __) {
        return
      Stack(
        children: [
          Consumer<NetworkService>(
            builder: (context, networkService, child) {
              if (networkService.networkStatus == NetworkStatus.Online) {
                if (networkService.toString().replaceAll('"', '') == config_wifi) {
                  wifi_sttus = 1;
                } else {
                  wifi_sttus = 0;
                }
                return (networkService.wifiName).toString().replaceAll('"', '') == config_wifi
                    ?
                SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: StreamBuilder(
                          stream: chats,
                          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.hasData) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {

                                if (!_isScrolledUp && _isNearBottom()) {
                                //  scrollToBottom_();
                                }
                              });

                              return
                              /*  ListView.builder(
                                itemCount: snapshot.data?.docs.length,
                                controller: _scrollController,
                                shrinkWrap: true,
                                reverse: false,
                                itemBuilder: (context, index) {
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
                              );*/

                                SingleChildScrollView(
                                  controller: _scrollController,
                                //  reverse: true,
                                  child: Column(
                                    children: snapshot.data!.docs.map((messageData) {
                                      var message = messageData["message"];
                                      bool sendByMe = Constants.myName == messageData["sendBy"];
                                      Timestamp time = messageData["time"];
                                      bool isRead = messageData["read"];
                                      bool isDelivered = messageData["delivered"];
                                      bool isSent = messageData["sent"];
                                      WidgetsBinding.instance.addPostFrameCallback((_) {


                                            scrollToBottom_();

                                      });

                                      return Messages(
                                        message: message,
                                        sendByMe: sendByMe,
                                        time: time,
                                        imageurl: imageurl,
                                        isRead: isRead,
                                        isDelivered: isDelivered,
                                        isSent: isSent,
                                        chatRoomId: chatRoomId,
                                        messageID: messageData.id,
                                      );
                                    }).toList(),
                                  ),
                                );

                            } else {
                              return Container();
                            }
                          },
                        ),
                      ),
                      Container(
                        alignment: Alignment.bottomCenter,
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onTap: () {
                                  _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(seconds: 2),
                                      curve: Curves.easeOut);
                                 // scrollToBottom(_scrollController);
                                },
                                controller: messageEditingController,
                                cursorColor: Colors.blue,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                decoration: kTextFieldDecoration.copyWith(hintText: 'Message...'),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                               // scrollToBottom_();
                                addMessage();
                                scrollToBottom_();
                                scrollToBottom(_scrollController);
                                _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: const Duration(seconds: 2),
                                    curve: Curves.easeOut);
                               // chatProvider.scrollToBottom(scrollController);
                               // scrollToBottom_();

                              },
                              icon: const Icon(Icons.send, color: Color(0xff03A0E3)),
                            ),
                           /* IconButton(
                              onPressed: scrollToTop,  // Call the scroll to top function
                              icon: const Icon(Icons.arrow_upward, color: Color(0xff03A0E3)),
                            ),*/
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    : _buildNoWifiUI();
              } else {
                return _buildNoWifiUI();
              }
            },
          ),
          if (_isScrolledUp)
            Positioned(
              bottom: 110,
              left: MediaQuery.of(context).size.width / 2 - 28,
              child:
              FloatingActionButton(
                backgroundColor: Colors.white,
                //elevation: 16.0,
                onPressed: (){
        scrollToBottom(_scrollController);
        },
                child: const Icon(Icons.keyboard_arrow_down_outlined,color: Colors.blue,),
                shape: const CircleBorder(

                ),
              ),
            ),
        ],
      );
      }),
    );

  }

  Widget _buildNoWifiUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 200,
            width: 200,
            padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
            child: Image.asset(
              "assets/images/nowifi.png",
              fit: BoxFit.contain,
            ),
          ),
          Text(
            "Please #getsocial! You are not connected.",
            style: GoogleFonts.poppins(
              color: Colors.black45,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          Text(
            "Please check your Wi-Fi connection.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.redAccent,
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
 /* @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(),
      body: Consumer<NetworkService>(
        builder: (context, networkService, child) {
          if (networkService.networkStatus == NetworkStatus.Online) {
            if (networkService.toString().replaceAll('"', '') == config_wifi) {
              wifi_sttus = 1;
            } else {
              wifi_sttus = 0;
            }
            return (networkService.wifiName).toString().replaceAll('"', '') == config_wifi
                ? SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: StreamBuilder(
                            stream: chats,
                            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.hasData) {
                                // Automatically scroll to the end when new data is loaded
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                              scrollToBottom(_scrollController);
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

                              } else {
                                return Container();
                              }
                            },
                          ),
                        ),

                        Container(
                          alignment: Alignment.bottomCenter,
                          width: MediaQuery.of(context).size.width,
                          //   height: 100,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                  child: TextField(
                                    onTap: () {

                                    scrollToBottom(_scrollController);
                                    },
                                controller: messageEditingController,
                                cursorColor: Colors.blue,
                                maxLines: null, // Allows the TextField to expand vertically
                                keyboardType: TextInputType.multiline, // Allows the user to enter multiple lines
                                textInputAction: TextInputAction.newline,
                                decoration: kTextFieldDecoration.copyWith(hintText: 'Message...'),
                              )),
                              IconButton(
                                  onPressed: () {
                                    //
                                    addMessage();
                                   scrollToBottom(_scrollController);
                                 *//*  Future.delayed(Duration(milliseconds: 300), () {
                                      if (_scrollController.hasClients) {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    });*//*
                                  },
                                  icon: const Icon(Icons.send, color: Color(0xff03A0E3)))
                            ],
                          ),
                        ),
                        //chatMessages()
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        *//* Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                              child: Text(
                                'Connected Wifi: $_connectionStatus',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w300,
                                ),
                              )),*//*
                        Container(
                          height: 200,
                          width: 200,
                          padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
                          *//*decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),*//*
                          child: Image.asset(
                            "assets/images/nowifi.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                        // SizedBox(height: screenHeight * 0.1),
                        Text(
                          "Please #getsocial! You are not connected. ",
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        //   SizedBox(height: screenHeight * 0.01),
                        *//*  Text(
              "Kindly await approval from the  manager \n before proceeding further.",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
            ),*//*

                        Text(
                          "Please check your Wi-Fi connection.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                        ),
                        //  SizedBox(height: screenHeight * 0.06),
                        *//* Flexible(
              child: HomeButton(
                title: 'Home',
                onTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) =>  Dashboard()));
                },
              ),
            ),*//*
                      ],
                    ),
                  );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  *//* Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                              child: Text(
                                'Connected Wifi: $_connectionStatus',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w300,
                                ),
                              )),*//*
                  Container(
                    height: 200,
                    width: 200,
                    padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
                    *//*decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),*//*
                    child: Image.asset(
                      "assets/images/nowifi.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  // SizedBox(height: screenHeight * 0.1),
                  Text(
                    "Please #getsocial! You are not connected. ",
                    style: GoogleFonts.poppins(
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                    ),
                  ),
                  //   SizedBox(height: screenHeight * 0.01),
                  *//*  Text(
              "Kindly await approval from the  manager \n before proceeding further.",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
            ),*//*

                  Text(
                    "Please check your Wi-Fi connection.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                    ),
                  ),
                  //  SizedBox(height: screenHeight * 0.06),
                  *//* Flexible(
              child: HomeButton(
                title: 'Home',
                onTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) =>  Dashboard()));
                },
              ),
            ),*//*
                ],
              ),
            );
          }
        },
      ),

      //  bottomNavigationBar: chatTextField1(context),
    );
  }*/



  String formatDate(String timestamp) {
    // Extract the date and time components
    List<String> dateTimeParts = timestamp.split('T');
    String datePart = dateTimeParts[0];
    String timePart = dateTimeParts[1].split('.')[0];

    // Parse the date
    DateTime dateTime = DateTime.parse('$datePart $timePart');

    // Extract and parse the timezone offset
    String offsetString = timestamp.substring(timestamp.length - 6);
    int hours = int.parse(offsetString.substring(0, 3));
    int minutes = int.parse(offsetString.substring(3));
    Duration offset = Duration(hours: hours, minutes: minutes);

    // Adjust the time according to the timezone offset
    dateTime = dateTime.subtract(offset);

    var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    String formatted = formatter.format(dateTime);
    return formatted;
  }

  Future<void> addmessage_server(String message, String globalTime) async {
    String formattedDate = "";
    if (globalTime.isEmpty || globalTime == null) {
      formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    } else {
      DateTime dateTime = DateTime.parse(globalTime).toLocal();

      var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      formattedDate = formatter.format(dateTime);
    }
    print('globaltime $globalTime');
    print('formattedDate $formattedDate');
    /*   String cetTime = convertLocalToCET(formattedDate);
    print('Final Converted CET Time: $cetTime');

    print('formattedDateffff $formattedDate');*/
    //  sendNotification(message, formattedDate);
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/chat_msg'));
    request.body = json.encode({"sender_id": senderid, "receiver_id": uid, "channel_id": chatRoomId, "message": message, "time": formattedDate});
    //print(json.encode({"sender_id": senderid, "receiver_id": uid, "channel_id": chatRoomId, "message": message, "time": formattedDate}));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  /*Future<void> sendnotifcation(String message, String time) async {
    var headers = {
      'Authorization': 'key=AAAAGLDkAjg:APA91bFsO9qoCm-dYTaDicJ9cHDsg8ur4HY-dqx2tRzSJrh1X7Lxg0c0pZrBEfSSnRoOHdAMUMuRe59YnWkKXFMA3BOTw5QLAqhXzUe_MQ6Bsuu71RvxGkJ5l23obQBayyOyLRJzXYk1',
      'Content-Type': 'application/json'
    };
    var request = http.Request('POST', Uri.parse('https://fcm.googleapis.com/fcm/send'));
    request.body = json.encode({
      "to": token,
      "data": {"body": message, "title": "New Message", "image": "", "key_2": time}
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }*/

  Future<void> sendNotification(String message, String time) async {
    var headers = {
      'Authorization':
          'key=AAAAGLDkAjg:APA91bFsO9qoCm-dYTaDicJ9cHDsg8ur4HY-dqx2tRzSJrh1X7Lxg0c0pZrBEfSSnRoOHdAMUMuRe59YnWkKXFMA3BOTw5QLAqhXzUe_MQ6Bsuu71RvxGkJ5l23obQBayyOyLRJzXYk1', // Replace with your actual FCM server key
      'Content-Type': 'application/json'
    };

    var request = http.Request('POST', Uri.parse('https://fcm.googleapis.com/fcm/send'));
    request.body = json.encode({
      "to": token, // Replace 'token' with the actual FCM token of the recipient
      "notification": {
        "title": "New Message",
        "body": message,
        "image": "" // If you have an image URL, include it here
      },
      "data": {
        "key_1": "value_1", // Custom data if needed
        "key_2": time
      }
    });

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }
}

Container chatTextField1(BuildContext context) {
  return Container(
      //  height: MediaQuery.of(context).size.height,
      // width: MediaQuery.of(context).size.width,
      // decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomLeft, colors: [Colors.blue.shade100, Colors.grey.shade100])),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.mic, color: Colors.blue),
            const SizedBox(width: kDefaultPadding),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.64),
                    ),
                    const SizedBox(width: kDefaultPadding / 4),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: "Type message",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.attach_file,
                      color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.64),
                    ),
                    const SizedBox(width: kDefaultPadding / 4),
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.64),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ));
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool sendByMe;

  MessageTile({required this.message, required this.sendByMe});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 8, bottom: 8, left: sendByMe ? 0 : 24, right: sendByMe ? 24 : 0),
        alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: sendByMe ? const EdgeInsets.only(left: 30) : const EdgeInsets.only(right: 30),
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
          decoration: BoxDecoration(
              borderRadius: sendByMe
                  ? const BorderRadius.only(bottomLeft: Radius.circular(0), topLeft: Radius.circular(10), topRight: Radius.circular(10), bottomRight: Radius.circular(10))
                  : const BorderRadius.all(Radius.circular(20)),
              color: sendByMe ? Colors.black12 : Colors.white),
          child: Text(message,
              textAlign: TextAlign.start,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  //fontWeight: FontWeight.bold,
                ),
              )),
        ));
  }
}

class Messages extends StatelessWidget {
  final String message;
  final bool sendByMe;
  final Timestamp time;
  final dynamic imageurl;
  final bool isRead;
  final String messageID;
  final String chatRoomId;
  final bool isDelivered;
  final bool isSent;

  Messages({
    Key? key,
    required this.message,
    required this.sendByMe,
    required this.time,
    required this.imageurl,
    required this.isRead,
    required this.messageID,
    required this.chatRoomId,
    required this.isDelivered,
    required this.isSent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _MessagesWidget(
      message: message,
      sendByMe: sendByMe,
      time: time,
      imageurl: imageurl,
      isRead: isRead,
      messageID: messageID,
      chatRoomId: chatRoomId,
      isDelivered: isDelivered,
      isSent: isSent,
    );
  }
}

class _MessagesWidget extends StatefulWidget {
  final String message;
  final bool sendByMe;
  final Timestamp time;
  final dynamic imageurl;
  final bool isRead;
  final String messageID;
  final String chatRoomId;
  final bool isDelivered;
  final bool isSent;

  _MessagesWidget({
    Key? key,
    required this.message,
    required this.sendByMe,
    required this.time,
    required this.imageurl,
    required this.isRead,
    required this.messageID,
    required this.chatRoomId,
    required this.isDelivered,
    required this.isSent,
  }) : super(key: key);

  @override
  _MessagesWidgetState createState() => _MessagesWidgetState();
}

/*class _MessagesWidgetState extends State<_MessagesWidget> {
  late bool _isRead;
  late Stream<DocumentSnapshot> readStatusStream;

  @override
  void initState() {
    super.initState();
    _isRead = widget.isRead;
    readStatusStream = DatabaseMethods().getMessageReadStatusStream(widget.chatRoomId, widget.messageID);
  }

  @override
  void didUpdateWidget(covariant _MessagesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.sendByMe && !_isRead) {
      setState(() {
        _isRead = widget.isRead;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = widget.time.toDate();
    String formattedTime = DateFormat('h:mm a').format(dateTime);

    return StreamBuilder<DocumentSnapshot>(
      stream: readStatusStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No message data available'));
        } else {
          print(!widget.sendByMe);
          print(!_isRead);
          if (!widget.sendByMe && !_isRead) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              DatabaseMethods().updateMessageReadStatus(widget.chatRoomId, widget.messageID);
              setState(() {
                _isRead = true;
              });
            });
          }

          return Padding(
            padding: const EdgeInsets.only(top: pDefaultPadding * 0.9, left: 5),
            child: Row(
              mainAxisAlignment: widget.sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!widget.sendByMe) ...[
                  Container(
                    height: 35,
                    width: 35,
                    child: Image.network(widget.imageurl),
                  ),
                ],
                const SizedBox(width: pDefaultPadding / 2),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: IntrinsicWidth(
                    child: widget.sendByMe
                        ? Container(
                            margin: const EdgeInsets.only(top: 0, right: 5),
                            padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 3),
                            decoration: const BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(0),
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.message,
                                    style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
                                  child: Row(
                                    children: [
                                      Text(
                                        formattedTime,
                                        style: GoogleFonts.poppins(
                                          color: Colors.black45,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      _isRead
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.blue,
                                              size: 15,
                                            )
                                          : const Icon(
                                              Icons.check_circle,
                                              color: Colors.grey,
                                              size: 15,
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.sendByMe ? Colors.black26 : pSecondaryColor,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                topLeft: Radius.circular(0),
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.message,
                                    style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black45,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}*/

class _MessagesWidgetState extends State<_MessagesWidget> {
  late bool _isRead;
  late Stream<DocumentSnapshot> readStatusStream;

  @override
  void initState() {
    super.initState();
    _isRead = widget.isRead;
    readStatusStream = DatabaseMethods().getMessageReadStatusStream(widget.chatRoomId, widget.messageID);
  }

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = widget.time.toDate();
    String formattedTime = DateFormat('h:mm a').format(dateTime);

    return StreamBuilder<DocumentSnapshot>(
      stream: readStatusStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return Container();
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container();
        } else {
          // Check if the message has been read
          bool isReadInDatabase = snapshot.data!['read'] ?? false;

          return VisibilityDetector(
            key: Key(widget.messageID),
            onVisibilityChanged: (visibilityInfo) {
              // Only mark the message as read if:
              // - The message is not sent by the current user
              // - It hasn't been marked as read yet
              // - At least 50% of the message is visible
              if (!widget.sendByMe && !_isRead && visibilityInfo.visibleFraction > 0.5) {
                DatabaseMethods().updateMessageReadStatus(widget.chatRoomId, widget.messageID);
                setState(() {
                  _isRead = true;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: pDefaultPadding * 0.9, left: 5),
              child: Row(
                mainAxisAlignment: widget.sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!widget.sendByMe) ...[
                    Container(
                      height: 35,
                      width: 35,
                      child: Image.network(widget.imageurl),
                    ),
                  ],
                  const SizedBox(width: pDefaultPadding / 2),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: IntrinsicWidth(
                      child: widget.sendByMe
                          ? Container(

                              margin: const EdgeInsets.only(top: 0, right: 5),
                              padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 3),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(0),
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.message,
                                      style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
                                    child: Row(
                                      children: [
                                        Text(
                                          formattedTime,
                                          style: GoogleFonts.poppins(
                                            color: Colors.black45,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        _isRead || isReadInDatabase
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Colors.blue,
                                                size: 15,
                                              )
                                            : const Icon(
                                                Icons.check_circle,
                                                color: Colors.grey,
                                                size: 15,
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(

                              padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 5),
                              decoration: BoxDecoration(
                                color: widget.sendByMe ? Colors.black26 : pSecondaryColor,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  topLeft: Radius.circular(0),
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.message,
                                      style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    formattedTime,
                                    style: GoogleFonts.poppins(
                                      color: Colors.black45,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

/*class _MessagesWidgetState extends State<_MessagesWidget> {
  late bool _isRead;

  @override
  void initState() {
    super.initState();
    _isRead = widget.isRead;
    if (!widget.sendByMe && !_isRead) {
      checkRegistrationStatus();
    }
  }

  void _updateReadStatus() {
    DatabaseMethods().updateMessageReadStatus(widget.chatRoomId, widget.messageID);
    setState(() {
      _isRead = true;
    });
  }

  void checkRegistrationStatus() async {
    _updateReadStatus();
    await Future.delayed(Duration(seconds: 3));

    if (mounted && !_isRead) {
      checkRegistrationStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = widget.time.toDate();
    String formattedTime = DateFormat('h:mm a').format(dateTime);

    return Padding(
      padding: const EdgeInsets.only(top: pDefaultPadding * 0.9, left: 5),
      child: Row(
        mainAxisAlignment: widget.sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.sendByMe) ...[
            Container(
              height: 35,
              width: 35,
              child: Image.network(widget.imageurl),
            )
          ],
          const SizedBox(
            width: pDefaultPadding / 2,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
            ),
            child: IntrinsicWidth(
              child: widget.sendByMe
                  ? Container(
                      margin: const EdgeInsets.only(top: 0, right: 5),
                      padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 3),
                      decoration: const BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(0),
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.message,
                              style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
                            child: Row(
                              children: [
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black45,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                _isRead
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                        size: 15,
                                      )
                                    : const Icon(
                                        Icons.check_circle,
                                        color: Colors.grey,
                                        size: 15,
                                      ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.sendByMe ? Colors.black26 : pSecondaryColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.message,
                              style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formattedTime,
                            style: GoogleFonts.poppins(
                              color: Colors.black45,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          )

          */ /* ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8, // 60% of screen width
            ),
            child: widget.sendByMe
                ? Container(
                    margin: const EdgeInsets.only(top: 0, right: 5),
                    padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 3),
                    decoration: const BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(0),
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                            //  overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
                          child: Row(
                            children: [
                              Text(
                                formattedTime,
                                style: GoogleFonts.poppins(
                                  color: Colors.black45,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 5),
                              _isRead
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 15,
                                    )
                                  : const Icon(
                                      Icons.check_circle,
                                      color: Colors.grey,
                                      size: 15,
                                    ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.sendByMe ? Colors.black26 : pSecondaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                            // overflow: TextOverflow.ellipsis,
                            // maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          formattedTime,
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),*/ /*
        ],
      ),
    );

    */ /* Padding(
      padding: const EdgeInsets.only(top: pDefaultPadding * 0.9, left: 5),
      child: Row(
        mainAxisAlignment: widget.sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.sendByMe) ...[
            Container(
              height: 35,
              width: 35,
              child: Image.network(widget.imageurl),
            )
          ],
          const SizedBox(
            width: pDefaultPadding / 2,
          ),
          widget.sendByMe
              ? Container(
                  // maxWidth: MediaQuery.of(context).size.width * 0.6,
                  margin: const EdgeInsets.only(top: 0, right: 5),
                  padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.message,
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                      ),
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
                        child: Row(
                          children: [
                            Text(
                              formattedTime,
                              style: GoogleFonts.poppins(
                                color: Colors.black45,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 5),
                            _isRead
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 15,
                                  )
                                : const Icon(
                                    Icons.check_circle,
                                    color: Colors.grey,
                                    size: 15,
                                  ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.sendByMe ? Colors.black26 : pSecondaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.message,
                          style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        formattedTime,
                        style: GoogleFonts.poppins(
                          color: Colors.black45,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );*/ /*
  }
}*/

// for showing single message details
