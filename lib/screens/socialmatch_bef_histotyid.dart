import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/screens/socailevents.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/NotificationService.dart';
import '../controller/loader.dart';
import '../helper/constants.dart';
import '../main.dart';
import '../services/database.dart';
import 'NetworkService.dart';
import 'chatlistnew.dart';
import 'chats.dart';
import 'myprofile.dart';

class SocilamatchList_befhistoryid extends StatefulWidget {
  final authcode;

  SocilamatchList_befhistoryid(this.authcode);

  _MyAppState createState() => _MyAppState(this.authcode);
}

class _MyAppState extends State<SocilamatchList_befhistoryid> {
  var authcode;
  _MyAppState(this.authcode);
  bool _isLoading = false;
  bool listvisible_flag = true;
  bool listvisible_flag1 = false;
  bool isInitializing = true;
  String? previousWifiName;
  bool _hasRefreshedList = false;
  bool _refreshListCalled = false;
  bool paynow_flag1 = false;
  bool _isStoredWifiNameMatched = false;
  List<dynamic> responseData = [];
  bool hasRefreshedList = false;
  bool isDisconnectedLoading = false;
  String username = "";
  String plantid = "";
  String erporderno = "";
  String consumerId = "";
  String outputDate_to1 = "";
  String requesttype = "";
  String? UserId = "";
  String shopidn = "";
  String? wifiNamenew;
  bool isLoading = true;
  QuerySnapshot? searchSnapshot;
  List<dynamic> activeUsersList = [];
  bool hasCheckedNetwork = false;
  DatabaseMethods databaseMethods = DatabaseMethods();
  TextEditingController searchTextEditingController = TextEditingController();
  bool haveUserSearched = false;
  int toggleindex = 0;
  int wifi_sttus = -1;
  String statuslable = "";
  dynamic colorcodelable;
  List<String> supplier_typelist = ["NEW REQUESTS", 'OLD REQUESTS'];
  Timer? _timer;
  String _connectionStatus = 'Unknown';
  late ConnectivityResult result;
  final AsyncMemoizer _memoizer = AsyncMemoizer();
  final NetworkInfo _networkInfo = NetworkInfo();
  Future<List>? _futureActiveUsersList;
  // final LocalStorage storage = new LocalStorage('wifi');
  String config_wifi = "";
  dynamic shop_id;
  String googlerul = "";
  String connected_wifi = "";
  List<dynamic> _cachedList = [];

  String formatChatTime(String chatTime) {
    if (chatTime == null || chatTime == 'null') {
      return "";
    }

    DateTime messageDate = DateTime.parse(chatTime);
    DateTime now = DateTime.now();

    // Check if the message was sent today
    if (messageDate.year == now.year && messageDate.month == now.month && messageDate.day == now.day) {
      return DateFormat.jm().format(messageDate); // Show time (e.g., 2:30 PM)
    }

    // Check if the message was sent yesterday
    DateTime yesterday = now.subtract(const Duration(days: 1));
    if (messageDate.year == yesterday.year && messageDate.month == yesterday.month && messageDate.day == yesterday.day) {
      return 'Yesterday';
    }

    // Otherwise, show the date (e.g., Jan 1, 2023)
    return DateFormat.yMMMd().format(messageDate);
  }

  Future<void> _updateUserStatus(int status) async {
    var headers = {'Content-Type': 'application/json'};

    //   final LocalStorage storage = LocalStorage('wifi');
    shopidn = localStorage.getItem('shopidn') ?? '';
    dynamic history_id = localStorage.getItem('history_id') ?? '';

    var request1 = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/update_status'));
    request1.body = json.encode({"status": 0, "id": UserId, "shop_id": shopidn, "history_id": history_id});
    request1.headers.addAll(headers);
    print(request1.body);

    http.StreamedResponse response1 = await request1.send();

    if (response1.statusCode == 200) {
      print(response1.reasonPhrase);
    } else {
      // print('RESPONSE2222');
      print(response1.reasonPhrase);
    }
  }

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  late FirebaseMessaging messaging;
  Future<void> registerForNotifications() async {
    messaging = FirebaseMessaging.instance;

    /* // Request permissions for iOS (does not affect Android)
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
*/

    await messaging.subscribeToTopic('flutter_notification');

    /* if (!kIsWeb) {
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

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Handling a foreground message: ${message.messageId}');
        print('Notification Message: ${message.data}');

        final data = message.data;
        final title = data['title'] ?? 'Notification Title';
        final body = data['body'] ?? 'Notification Body';
        final imageUrl = data['image'] ?? '';

        if (imageUrl.isNotEmpty) {
          showNotificationDialog(title, body, imageUrl);
        }

        NotificationService().showNotification(title: title, body: body);
      });
    }*/

    if (!kIsWeb) {
      // Define the notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'flutter_notification', // channel ID
        'Flutter Notification', // channel name
        importance: Importance.high,
        enableLights: true,
        enableVibration: true,
        showBadge: true,
        playSound: true,
      );

      // Initialize flutter_local_notifications plugin
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Configure initialization settings
      const AndroidInitializationSettings android = AndroidInitializationSettings('@drawable/ic_notifications_icon');

      const InitializationSettings initSettings = InitializationSettings(
        android: android,
      );

      // Initialize flutter_local_notifications plugin with the settings
      final bool? initialized = await flutterLocalNotificationsPlugin?.initialize(
        initSettings,
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (initialized == null || !initialized) {
        // Handle initialization error
        print("Error: flutterLocalNotificationsPlugin failed to initialize");
        return;
      }

      // Set foreground notification presentation options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('Handling a foreground message: ${message.messageId}');
        print('Notification Message: ${message.data}');

        final data = message.data;
        final title = data['title'] ?? '';
        final body = data['body'] ?? 'Notification Body';
        final imageUrl = data['image'] ?? '';

        if (data == null || data.isEmpty) {
          print('Received message data is null or empty');
          return; // Exit if data is null or empty
        } else {
          if (imageUrl.isNotEmpty) {
            await NotificationService().showNotificationWithImage(title, body, imageUrl);
            // Show notification dialog if image URL is provided
            showNotificationDialog(title, body, imageUrl);
          }
          NotificationService().showNotification(title: title, body: body);
        }

        // Show notification
      });

      // Listen for background messages
      FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
        print('Handling a background message: ${message.messageId}');
        print('Notification Message: ${message.data}');

        final data = message.data;
        final title = data['title'] ?? 'Notification Title';
        final body = data['body'] ?? 'Notification Body';
        final imageUrl = data['image'] ?? '';

        if (data == null || data.isEmpty) {
          print('Received message data is null or empty');
          return; // Exit if data is null or empty
        } else {
          if (imageUrl.isNotEmpty) {
            // Show notification dialog if image URL is provided
            showNotificationDialog(title, body, imageUrl);
            await NotificationService().showNotificationWithImage(title, body, imageUrl);
          }
          NotificationService().showNotification(title: title, body: body);
        }

        // Show notification
      });
    }
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(Uri.parse(googlerul))) {
      throw Exception('Could not launch $googlerul');
    }
  }

  void showNotificationDialog(String title, String body, String imageUrl) {
    showDialog(
      context: context,
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
                        return const SizedBox(
                          height: 100, // Placeholder height
                          child: Center(
                              child: Center(
                                  child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff03A0E3)),
                          ))),
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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeNetworkStatus() async {
    // Simulate a delay to fetch network status (if needed)
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      isInitializing = false;
    });
  }

  // Other varia
  @override
  void initState() {
    activeUsersList = [];
    super.initState();

    registerForNotifications();
    _initializeNetworkStatus();
    retrive();

    //   _initNetworkInfonew();

    // _initConnectivity_new();
    // _initConnectivity();
    // startChecking();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  Future<void> retrieveWifiName() async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/wifi_details'));
    request.body = json.encode({"wifi_name": connected_wifi});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseBody);

        // Ensure that the 'data' field is present and contains 'wifi_name'
        if (responseData.containsKey('data') && responseData['data'] != null) {
          Map<String, dynamic> data = responseData['data'];
          if (data.containsKey('wifi_name') && data['wifi_name'] != null) {
            String wifiName = data['wifi_name'];
            String url_ = data['google_url'];
            dynamic shopid = data['id'];
            dynamic history_id = responseData['history_id'].toString();
            print('history_id: $history_id');
            print('WiFi Name: $wifiName');

            setState(() {
              config_wifi = wifiName;
              shop_id = shopid;
              googlerul = url_;
            });

            /*  config_wifi = wifiName;
            shop_id = shopid;
            googlerul = url_;*/
            savePost1(wifiName, wifiName, shopid, url_, history_id);
            // Now you can use the WiFi name as needed
          } else {
            print('WiFi name not found or is null in the data');
          }
        } else {
          print('Data not found or is null in the response');
        }
      } else {
        print('Failed to retrieve WiFi name: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  savePost1(String name, String ssid, dynamic shopid, String url, dynamic history_id) async {
    // await storage.ready;
    localStorage.setItem("wifiname", name);
    localStorage.setItem("SSID", ssid);
    localStorage.setItem("shopid", shopid);
    localStorage.setItem("url", url);
    localStorage.setItem("history_id", history_id);
  }

  Future<void> retrivewww() async {
    //  await storage.ready;
    String? name = localStorage.getItem('wifiname');
    String? ssid = localStorage.getItem('SSID');
    config_wifi = localStorage.getItem('wifiname') ?? 'errrr';
    googlerul = localStorage.getItem('url') ?? "";
  }

  Future<void> _refreshList() async {
    try {
      List<dynamic> newActiveUsersList = await _fetchListItemsnew(UserId, connected_wifi, shop_id);
      setState(() {
        activeUsersList = newActiveUsersList;
        activeUsersList.sort((a, b) {
          DateTime timeA = a['chat_time'] == null || a['chat_time'] == 'null' ? DateTime.fromMillisecondsSinceEpoch(0) : DateFormat("yyyy-MM-dd HH:mm:ss").parse(a['chat_time']);
          DateTime timeB = b['chat_time'] == null || b['chat_time'] == 'null' ? DateTime.fromMillisecondsSinceEpoch(0) : DateFormat("yyyy-MM-dd HH:mm:ss").parse(b['chat_time']);
          return timeB.compareTo(timeA); // Descending order, latest chats first
        });
      });
    } catch (e) {
      print("Error in refreshing list: $e");
    }
  }

  Future<void> _refreshListnew() async {
    try {
      List<dynamic> newActiveUsersList = await _fetchListItemsnew(UserId, "errror@", shop_id);
      setState(() {
        activeUsersList = newActiveUsersList;
        activeUsersList.sort((a, b) {
          DateTime timeA = a['chat_time'] == null || a['chat_time'] == 'null' ? DateTime.fromMillisecondsSinceEpoch(0) : DateFormat("yyyy-MM-dd HH:mm:ss").parse(a['chat_time']);
          DateTime timeB = b['chat_time'] == null || b['chat_time'] == 'null' ? DateTime.fromMillisecondsSinceEpoch(0) : DateFormat("yyyy-MM-dd HH:mm:ss").parse(b['chat_time']);
          return timeB.compareTo(timeA); // Descending order, latest chats first
        });
      });
    } catch (e) {
      print("Error in refreshing list: $e");
    }
  }

  _fetchListItems(dynamic userid, String ssid) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/social_api'));
    request.body = json.encode({
      "user_id": userid,
      "ssid": ssid,
      "status": 1,
    });

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseString = await response.stream.bytesToString();

      List<dynamic> jsonDataList = json.decode(responseString);
      // Access the first element in the list
      dynamic jsonData1 = jsonDataList[0];

      // Access the "Campaigns" key and its value (which is a list)
      activeUsersList = jsonData1['data'];
    } else {
      if (kDebugMode) {
        print(response.reasonPhrase);
      }
    }
  }

  Future<List<dynamic>> _fetchListItemsnew(dynamic userid, String config_wifi, dynamic shopid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    print(UserId);

    var headers = {'Content-Type': 'application/json'};
    var url = Uri.parse('https://connfy.ragutis.com/api/social_api');
    var body = json.encode({
      "status": 1,
      "user_id": UserId,
      "ssid": config_wifi,
    });
    //   print(body);
    if (kDebugMode) {}

    const int maxRetries = 3;
    const Duration timeoutDuration = Duration(seconds: 3);
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Create a new Request object for each retry attempt
        var request = http.Request('POST', url);
        request.body = body;
        request.headers.addAll(headers);

        http.StreamedResponse response = await request.send().timeout(timeoutDuration);

        if (response.statusCode == 200) {
          String responseString = await response.stream.bytesToString();
          Map<String, dynamic> responseData = json.decode(responseString);
          //    print("responseString $responseString");
          if (kDebugMode) {
            // print("responseString $responseString");
          }
          if (responseData.containsKey('data')) {
            setState(() {
              _cachedList = responseData['data'];
            });
            var history_id = responseData['history_id'].toString();
            var wifiDetails = responseData['wifi_details'];
            var wifiName = wifiDetails['wifi_name'];
            var shopid = wifiDetails['id'];

            var url_ = wifiDetails['google_url'];
            print('history_id');
            print(history_id);

            savePost1(wifiName, wifiName, shopid, url_, history_id);
            retrivewww();
            // Update the state with the fetched WiFi name
            setState(() {
              config_wifi = wifiName;
              hasRefreshedList = false;
            });
            setState(() {
              isLoading = false;
            });

            // Cache the fetched data
            return _cachedList; // Return the fetched data
          } else {
            savePost1("errrr", "eeeee", "", "url_", "");
            retrivewww();
            setState(() {
              hasRefreshedList = true;
              config_wifi = "Error@1233";
            });
            setState(() {
              isLoading = false;
            });
            print("Error: 'data' key not found in the response");
            return [];
          }
        } else {
          setState(() {
            isLoading = false;
          });
          if (kDebugMode) {
            print(" server Error: ${response.reasonPhrase}");
          }
          return Future.value([]);
        }
      } on TimeoutException {
        setState(() {
          isLoading = false;
        });
        if (kDebugMode) {
          print("Error: Request timed out. Retrying (${retryCount + 1}/$maxRetries)...");
        }
      } on http.ClientException {
        setState(() {
          isLoading = false;
        });
        if (kDebugMode) {
          print("Error: Connection reset by peer. Retrying (${retryCount + 1}/$maxRetries)...");
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (kDebugMode) {
          print("API Exception: $e");
        }
        return Future.value([]);
      }

      retryCount++;
      await Future.delayed(const Duration(seconds: 2)); // Wait before retrying
    }

    return Future.value([]);
  }

  /* Future<List<dynamic>> _fetchListItemsnew(dynamic userid, String config_wifi) async {
    var headers = {'Content-Type': 'application/json'};
    var url = Uri.parse('https://connfy.ragutis.com/api/social_api');
    var body = json.encode({"status": 1, "user_id": userid, "ssid": config_wifi});
    //  print(json.encode({"status": 1, "user_id": userid, "ssid": config_wifi}));

    var request = http.Request('POST', url);
    request.body = body;
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        print(responseString);
        Map<String, dynamic> responseData = json.decode(responseString);

        if (responseData.containsKey('data')) {
          return Future.value(responseData['data']);
        } else {
          // Handle error if 'data' key is not found
          print("Error: 'data' key not found in the response");
          return Future.value([]);
        }
      } else {
        print("Error: ${response.reasonPhrase}");
        return Future.value([]);
      }
    } catch (e) {
      print("Exceptionddfsf: $e");
      return Future.value([]);
    }
  }
*/
  /* void _startTimer() {
    const duration = Duration(seconds: 60);
    _timer = Timer.periodic(duration, (Timer timer) {
      _initConnectivity();

      // Call your method here
    });
  }*/

  // Update connection status

  Future retrive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    print(UserId);
    print(_cachedList.length);
    var networkService = Provider.of<NetworkService>(context, listen: false);

    await networkService.initNetworkInfoOld();

    //  _refreshList();
    //_initNetworkInfo();

    //  _timer = Timer.periodic(Duration(seconds: 3), (Timer t) => _initNetworkInfo());
  }

  Widget _buildConnectedUI(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: const Color(0xffffffff),
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshList,
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: _cachedList.length,
                itemBuilder: (ctx, index) {
                  var user = _cachedList[index];

                  return user['chat_id'] == Constants.myName
                      ? Container()
                      : GestureDetector(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(0, 0, 0, 1),
                            color: Colors.transparent,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(0),
                                        bottomRight: Radius.circular(0),
                                        bottomLeft: Radius.circular(0),
                                        topRight: Radius.circular(0),
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
                                          height: 80,
                                          width: 80,
                                          child: CachedNetworkImage(
                                            imageUrl: user['horoscope_image_url'],
                                            placeholder: (context, url) => Image.asset('assets/images/photo.png', fit: BoxFit.contain),
                                            errorWidget: (context, url, error) => Image.asset('assets/images/photo.png', fit: BoxFit.contain),
                                            fit: BoxFit.contain,
                                            width: 80,
                                            height: 80,
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      user['name'] ?? '',
                                                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            user['chat_message'] == null || user['chat_message'] == 'null' ? "" : user['chat_message'],
                                                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w400),
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                user['chat_time'] == null || user['chat_time'] == 'null' ? "" : formatChatTime(user['chat_time']),
                                                style: GoogleFonts.poppins(color: const Color(0xff03A0E3), fontWeight: FontWeight.w400, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        )

                                        /*  Flexible(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: <Widget>[
                                                    SizedBox(
                                                      width: MediaQuery.of(context).size.width / 2,
                                                      child: Text(
                                                        user['name'] ?? "",
                                                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: <Widget>[
                                                        Text(
                                                          user['chat_time'] == null || user['chat_time'] == 'null' ? "" : formatChatTime(user['chat_time']),
                                                          style: GoogleFonts.poppins(color: Color(0xff03A0E3), fontWeight: FontWeight.w400, fontSize: 14),
                                                        ),
                                                        const SizedBox(width: 5),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: <Widget>[
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                      child: Text(
                                                        user['chat_message'] == null || user['chat_message'] == 'null' ? "" : user['chat_message'],
                                                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w400),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),*/
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    color: Color(
                                      0xffd8d8d8,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          onTap: () {
                            createChatroomAndStartConversation(
                              user['chat_id'],
                              user['name'],
                              user['id'].toString(),
                              user['horoscope_image_url'].toString(),
                              user['mobile_device_id'].toString(),
                            );
                          },
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          /* Container(
            height: 40,
            width: 300,
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              'Config:' + connected_wifi,
              style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),*/
          Container(
            height: 200,
            width: 200,
            padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
            child: Image.asset("assets/images/nowifi.png", fit: BoxFit.contain),
          ),
          Text(
            "Please #getsocial! You are not connected.",
            style: GoogleFonts.poppins(color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 15),
          ),
          Text(
            "Please check your Wi-Fi connection.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w400, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Future<void> wificheck(String ssid) async {
    if (ssid == null || ssid.isEmpty) {
      print('SSID is null or empty');
      return;
    }

    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/wifi_check'));
    request.body = json.encode({"ssid": ssid});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String jsonData = await response.stream.bytesToString();
      Map<String, dynamic> responseData = jsonDecode(jsonData);
      print(responseData);
      setState(() {
        wifi_sttus = responseData['status_match'];
      });

      print(wifi_sttus);

      if (wifi_sttus == 0) {
        //   _fetchListItems(UserId);
      } else {}

      String mobileDeviceId = responseData['data'];
      print(mobileDeviceId);
    } else {
      print(response.reasonPhrase);
    }
  }

  createChatroomAndStartConversation(String uid, String username, String userid, dynamic imageurl, String token) {
    print(uid);
    print(Constants.myName);
    if (uid != Constants.myName) {
      String chatRoomId = getChatRoomId(uid, Constants.myName);
      List<String> users = [Constants.myName, uid];
      Map<String, dynamic> chatRoomMap = {
        "chatroomId": chatRoomId,
        "users": users,
      };
      databaseMethods.addChatRoom(chatRoomMap, chatRoomId);
      Navigator.push(context, MaterialPageRoute(builder: (context) => Chat(chatRoomId, uid, username, "1", userid, imageurl, Constants.myName, token)));
    } else {
      print("you cannot send message to yourself");
    }
  }

  getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  void parseResponseData(Map<String, dynamic> userData) {
    // Extract data from responseData and handle it as needed
    // For example:
    String userId = userData['Messsage'];

    // Access more fields as needed

    print('User ID: $userId');
  }

  List<bool> _selections = List.generate(2, (_) => false);
  var appBarHeight = AppBar().preferredSize.height;
  var _popupMenuItemIndex = 0;
  Color _changeColorAccordingToMenuItem = Colors.red;
  String _onDropDownChanged_stype(String val) {
    var prefix;
    if (val.length > 0) {
      prefix = val;
    } else {
      prefix = "Select Requests";
    }

    return prefix;
  }

  Widget getAppBottomView() {
    return Container(
      padding: const EdgeInsets.only(left: 5, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Image.asset(
            "assets/images/confywhite.png",
            fit: BoxFit.contain,
            height: 58,
          ),
          PopupMenuButton(
            color: const Color(0xff03A0E3),
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'pro',
                  child: Text(
                    'My Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ];
            },
            onSelected: (String value) {
              if (value == 'pro') {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyProfilePage("2")));
              }
              print('You Click on po up menu item');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[loadUi(), _isLoading ? Loader(loadingTxt: 'Please wait..') : Container()],
    );
  }

  Widget getAppBottomViewnew(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 5, bottom: 10, top: 5),
      //height: 100, // Set a fixed height for the container
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Image.asset(
            "assets/images/confywhite.png",
            fit: BoxFit.contain,
            height: 58,
            color: Colors.white,
          ),
          Row(
            children: [
              PopupMenuButton(
                color: Colors.white,
                iconColor: Colors.white,
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: 'pro',
                      child: Text(
                        'My Profile ',
                        style: TextStyle(color: Color(0xff03A0E3)),
                      ),
                    ),
                  ];
                },
                onSelected: (String value) {
                  print('value');
                  print(value);
                  if (value.toString() == 'pro') {
                    print(Provider.of<NetworkService>(context, listen: false).wifiName.toString().replaceAll('"', ''));
                    //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyProfilePage("1")));
                    bool isConnectedToConfiguredWifi = Provider.of<NetworkService>(context, listen: false).wifiName.toString().replaceAll('"', '') == config_wifi;
                    print('isConnectedToConfiguredWifi');
                    print(isConnectedToConfiguredWifi);
                    print(config_wifi);
                    print(Provider.of<NetworkService>(context, listen: false).wifiName.toString().replaceAll('"', ''));
                    if (isConnectedToConfiguredWifi == true) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyProfilePage("2")));
                    }
                  } else {
                    print('value : $value');
                  }
                  print('You Click on popup menu item');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget loadUi() {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: Container(),
            backgroundColor: const Color(0xff03A0E3),
            bottom: PreferredSize(child: getAppBottomViewnew(context), preferredSize: const Size.fromHeight(20.0)),
          ),
          body: isInitializing
              ? const Center(
                  child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff03A0E3)),
                ))
              :
              /* Consumer<NetworkService>(
                  builder: (context, networkService, child) {
                    String wifiName = networkService.wifiName?.toString()?.replaceAll('"', '') ?? '';
                    connected_wifi = wifiName;
                    print("connected_wifi $connected_wifi");

                    return FutureBuilder(
                      future: storage.ready,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          String? storedWifiName = storage.getItem('wifiName') ?? '';
                          print("${storedWifiName!} === $wifiName");

                          bool isConnectedToConfiguredWifi = wifiName == config_wifi;
                          bool isStoredWifiNameMatched = storedWifiName.isNotEmpty && storedWifiName == wifiName;

                          // Manage Timer
                          if (isStoredWifiNameMatched) {
                            if (!_isStoredWifiNameMatched) {
                              _refreshList();
                              _isStoredWifiNameMatched = true;
                              _timer = Timer.periodic(Duration(seconds: 5), (timer) {
                                print("dffff");
                                _refreshList();
                                // Ensure that UI is refreshed
                                setState(() {});
                              });
                            }
                          } else {
                            if (_isStoredWifiNameMatched) {
                              _isStoredWifiNameMatched = false;
                              _timer?.cancel(); // Stop the timer when not matched
                            }
                          }

                          if (isStoredWifiNameMatched) {
                            return _buildConnectedUI(context);
                          } else {
                            if (!_refreshListCalled) {
                              _refreshListCalled = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _updateUserStatus(0);
                              });
                            }
                            return _buildDisconnectedUI();
                          }
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff03A0E3)),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),*/

              Consumer<NetworkService>(
                  builder: (context, networkService, child) {
                    String wifiName = networkService.wifiName?.toString()?.replaceAll('"', '') ?? '';
                    connected_wifi = wifiName;
                    print("connected_wifi $connected_wifi");

                    return FutureBuilder(
                      future: null,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          String? storedWifiName = localStorage.getItem('wifiName') ?? '';
                          print("${storedWifiName!} === $wifiName");

                          bool isConnectedToConfiguredWifi = wifiName == config_wifi;
                          bool isStoredWifiNameMatched = storedWifiName.isNotEmpty && storedWifiName == wifiName;

                          if (isStoredWifiNameMatched) {
                            // Refresh the list only if necessary
                            if (!_isStoredWifiNameMatched) {
                              _refreshList();
                              _isStoredWifiNameMatched = true;
                            }
                          } else {
                            _isStoredWifiNameMatched = false;
                          }

                          // Ensure that UI is refreshed after updating the list

                          if (isStoredWifiNameMatched) {
                            return _buildConnectedUI(context);
                          } else {
                            if (!_refreshListCalled) {
                              _refreshListCalled = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _updateUserStatus(0);
                              });
                            }
                            return _buildDisconnectedUI();
                          }
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff03A0E3)),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),

          /*Consumer<NetworkService>(
                  builder: (context, networkService, child) {
                    String wifiName = networkService.wifiName?.toString()?.replaceAll('"', '') ?? '';
                    connected_wifi = wifiName;
                    print("connected_wifi $connected_wifi");

                    // Retrieve stored Wi-Fi name from local storage
                    return FutureBuilder(
                      future: storage.ready,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          String? storedWifiName = storage.getItem('wifiName') ?? '';
                          print("${storedWifiName!} === $wifiName");

                          bool isConnectedToConfiguredWifi = wifiName == config_wifi;
                          bool isStoredWifiNameMatched = storedWifiName.isNotEmpty && storedWifiName == wifiName;

                          if (isStoredWifiNameMatched) {
                            if (!_refreshListCalled) {
                              _refreshListCalled = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _refreshList();
                              });
                            } else if (_refreshListCalled && !isConnectedToConfiguredWifi) {
                              _refreshListCalled = false; // Reset the flag to allow future updates
                            }
                            return _buildConnectedUI(context);
                          } else {
                            if (!_refreshListCalled) {
                              _refreshListCalled = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _updateUserStatus(0);
                              });
                            } else if (_refreshListCalled && isConnectedToConfiguredWifi) {
                              _refreshListCalled = false; // Reset the flag to allow future updates
                            }
                            return _buildDisconnectedUI();
                          }
                        } else {
                          // Show loading indicator while waiting for local storage to be ready
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff03A0E3)),
                            ),
                          );
                        }
                      },
                    );

                    */ /*FutureBuilder(
                      future: storage.ready,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          String? storedWifiName = storage.getItem('wifiName') ?? '';
                          print("${storedWifiName!}===$wifiName");
                          */ /* */ /*    Fluttertoast.showToast(
                              msg: 'WIFI CHECK: ${storedWifiName!}===$wifiName',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              textColor: Colors.white,
                              fontSize: 16.0);*/ /* */ /*
                          // Compare stored Wi-Fi name with current Wi-Fi name
                          if (storedWifiName.isNotEmpty && storedWifiName == wifiName) {
                            if (!_refreshListCalled) {
                              _refreshListCalled = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _refreshList();
                              });
                            }

                            return _buildConnectedUI(context);
                          } else {
                            if (!_refreshListCalled) {
                              _refreshListCalled = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _updateUserStatus(0);
                              });
                            }
                            return _buildDisconnectedUI();
                            // Update the local storage with the current Wi-Fi name
                            // storage.setItem('wifiName', wifiName);
                          }

                          bool isConnectedToConfiguredWifi = wifiName == config_wifi;
                          print('$wifiName === $config_wifi');

                          if (networkService.networkStatus == NetworkStatus.Online) {
                            // If online and connected to configured Wi-Fi
                            return _buildConnectedUI(context);
                          } else {
                            print("ELSE");
                            if (isDisconnectedLoading) {
                              // Show loading indicator when disconnected loading is in progress
                              return Center(child: CircularProgressIndicator());
                            } else if (isConnectedToConfiguredWifi) {
                              // Show connected UI if still connected to configured Wi-Fi
                              return _buildConnectedUI(context);
                            } else {
                              // Show disconnected UI if not connected to configured Wi-Fi
                              return _buildDisconnectedUI();
                            }
                          }
                        } else {
                          // Show loading indicator while waiting for local storage to be ready
                          return Center(
                              child: Center(
                                  child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff03A0E3)),
                          )));
                        }
                      },
                    );*/ /*
                  },
                ),*/

          /*Consumer<NetworkService>(
                  builder: (context, networkService, child) {
                    String wifiName = networkService.wifiName?.toString()?.replaceAll('"', '') ?? '';
                    bool isConnectedToConfiguredWifi = wifiName == config_wifi;
                    print('$wifiName === $config_wifi');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      //  _refreshList();
                    });
                    if (networkService.networkStatus == NetworkStatus.Online) {
                      // If online and connected to configured Wi-Fi
                      //   _refreshList();
                      return _buildConnectedUI(context);
                    } else {
                      print("ELSE");
                      if (isDisconnectedLoading) {
                        // Show loading indicator when disconnected loading is in progress
                        return Center(child: CircularProgressIndicator());
                      } else if (isConnectedToConfiguredWifi) {
                        // Show connected UI if still connected to configured Wi-Fi
                        //  _refreshList(); // Check and refresh list if Wi-Fi changed
                        return _buildConnectedUI(context);
                      } else {
                        // Show disconnected UI if not connected to configured Wi-Fi
                        return _buildDisconnectedUI();
                      }
                    }
                  },
                ),*/

          /*  Consumer<NetworkService>(
                  builder: (context, networkService, child) {
                    String wifiName = networkService.wifiName?.toString()?.replaceAll('"', '') ?? '';
                    connected_wifi = wifiName;
                    bool isConnectedToConfiguredWifi = wifiName == config_wifi;
                    print('$wifiName === $config_wifi');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _refreshList();
                    });
                    if (networkService.networkStatus == NetworkStatus.Online && isConnectedToConfiguredWifi) {
                      connected_wifi = wifiName;
                      return _buildConnectedUI(context);
                    } else {
                      print("ELSE");
                      connected_wifi = wifiName;

                      if (isDisconnectedLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else if (isConnectedToConfiguredWifi) {
                        return _buildConnectedUI(context);
                      } else {
                        return _buildDisconnectedUI();
                      }
                    }
                  },
                ),*/
          /* Consumer<NetworkService>(
            builder: (context, networkService, child) {
              if (networkService.networkStatus == NetworkStatus.Online) {
                print(networkService.wifiName.toString().replaceAll('"', '') + "====" + config_wifi);
                if (networkService.wifiName.toString().replaceAll('"', '') == config_wifi) {
                  wifi_sttus = 1;
                  connected_wifi = networkService.wifiName.toString().replaceAll('"', '');
                  _refreshList();
                } else {
                  wifi_sttus = 0;
                  connected_wifi = "gdtg@@@@";
                  _refreshList();
                }
                return (networkService.wifiName).toString().replaceAll('"', '') == config_wifi
                    ? Container(
                        // padding: const EdgeInsets.all(3.0),
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        color: Color(0xffe5e5e5),

                        child: Column(
                          children: <Widget>[
                            */
          /*  Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                          child: Text(
                            'Connected Wifi: $_connectionStatus',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w300,
                            ),
                          )),*/
          /*
                            */
          /*    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                        child: Text(
                          'Connected Wifi: $wifiNamenew',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),*/
          /*
                            */
          /* const SizedBox(
                        height: 20,
                      ),*/
          /*

                            // Here, default theme colors are used for activeBgColor, activeFgColor, inactiveBgColor and inactiveFgColor

                            Visibility(
                              visible: true,
                              child: Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _refreshList,
                                  child: ListView.builder(
                                    scrollDirection: Axis.vertical,
                                    itemCount: activeUsersList.length,
                                    itemBuilder: (ctx, index) {
                                      return activeUsersList[index]['chat_id'] == Constants.myName
                                          ? Container(
                                              */
          /*padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                        child: Text(
                                          'Connected Wifi: $_connectionStatus',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        )*/
          /*
                                              )
                                          : GestureDetector(
                                              child: Container(
                                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 1),
                                                color: Colors.transparent,
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                                                  child: Column(
                                                    children: <Widget>[
                                                      Container(
                                                        margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                                                        child: Container(
                                                          decoration: const BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.only(
                                                              topLeft: Radius.circular(0),
                                                              bottomRight: Radius.circular(0),
                                                              bottomLeft: Radius.circular(0),
                                                              topRight: Radius.circular(0),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: <Widget>[
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
                                                                height: 80,
                                                                width: 80,
                                                                child: CachedNetworkImage(
                                                                  imageUrl: activeUsersList[index]['horoscope_image_url'],
                                                                  placeholder: (context, url) => Image.asset('assets/images/photo.png', fit: BoxFit.contain),
                                                                  errorWidget: (context, url, error) {
                                                                    print("Error loading image: $error");
                                                                    return Image.asset('assets/images/photo.png', fit: BoxFit.contain);
                                                                  },
                                                                  fit: BoxFit.contain,
                                                                  width: 80,
                                                                  height: 80,
                                                                ),
                                                              ),
                                                              Flexible(
                                                                flex: 2,
                                                                child: Padding(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: <Widget>[
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: <Widget>[
                                                                          Container(
                                                                            width: MediaQuery.of(context).size.width / 2,
                                                                            child: Text(
                                                                              activeUsersList[index]['name'] == null ? "" : activeUsersList[index]['name'],
                                                                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                                                                            ),
                                                                          ),
                                                                          Row(
                                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                                            children: <Widget>[
                                                                              Text(
                                                                                activeUsersList[index]['chat_time'] == null || activeUsersList[index]['chat_time'] == 'null'
                                                                                    ? ""
                                                                                    : formatChatTime(activeUsersList[index]['chat_time']),
                                                                                style: GoogleFonts.poppins(color: Color(0xff03A0E3), fontWeight: FontWeight.w400, fontSize: 14),
                                                                              ),
                                                                              const SizedBox(
                                                                                width: 5,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: <Widget>[
                                                                          Container(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                            child: Text(
                                                                              activeUsersList[index]['chat_message'] == null || activeUsersList[index]['chat_message'] == 'null'
                                                                                  ? ""
                                                                                  : activeUsersList[index]['chat_message'],
                                                                              style: GoogleFonts.poppins(
                                                                                fontSize: 14,
                                                                                color: Colors.black54,
                                                                                fontWeight: FontWeight.w400,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            width: 5,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                createChatroomAndStartConversation(
                                                  activeUsersList[index]['chat_id'],
                                                  activeUsersList[index]['name'],
                                                  activeUsersList[index]['id'].toString(),
                                                  activeUsersList[index]['horoscope_image_url'].toString(),
                                                );
                                              },
                                            );
                                    },
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            */
          /* Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                              child: Text(
                                'Connected Wifi: $_connectionStatus',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w300,
                                ),
                              )),*/
          /*
                            Container(
                              height: 200,
                              width: 200,
                              padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
                              */
          /*decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),*/
          /*
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
                            */
          /*  Text(
              "Kindly await approval from the  manager \n before proceeding further.",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
            ),*/
          /*

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
                            */
          /* Flexible(
              child: HomeButton(
                title: 'Home',
                onTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) =>  Dashboard()));
                },
              ),
            ),*/
          /*
                          ],
                        ),
                      );
              } else {
                wifi_sttus = 0;
                connected_wifi = "gdtg@@@@";

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      */
          /* Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                              child: Text(
                                'Connected Wifi: $_connectionStatus',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w300,
                                ),
                              )),*/
          /*
                      Container(
                        height: 200,
                        width: 200,
                        padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
                        */
          /*decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),*/
          /*
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
                      */
          /*  Text(
              "Kindly await approval from the  manager \n before proceeding further.",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
            ),*/
          /*

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
                      */
          /* Flexible(
              child: HomeButton(
                title: 'Home',
                onTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) =>  Dashboard()));
                },
              ),
            ),*/
          /*
                    ],
                  ),
                );
              }
            },
          ),*/

          /*Consumer<NetworkService>(
            builder: (context, networkService, child) {
              if (_isLoading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              String wifiName = networkService.wifiName?.toString()?.replaceAll('"', '') ?? '';
              bool isConnectedToConfiguredWifi = wifiName == config_wifi;

              if (networkService.networkStatus == NetworkStatus.Online) {
                if (isConnectedToConfiguredWifi) {
                  wifi_sttus = 1;
                  connected_wifi = wifiName;
                } else {
                  wifi_sttus = 0;
                  connected_wifi = "gdtg@@@@";
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _refreshList();
                });

                return isConnectedToConfiguredWifi
                    ? Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        color: Color(0xffe5e5e5),
                        child: Column(
                          children: <Widget>[
                            Visibility(
                              visible: true,
                              child: Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _refreshList,
                                  child: ListView.builder(
                                    scrollDirection: Axis.vertical,
                                    itemCount: activeUsersList.length,
                                    itemBuilder: (ctx, index) {
                                      var user = activeUsersList[index];
                                      return user['chat_id'] == Constants.myName
                                          ? Container()
                                          : GestureDetector(
                                              child: Container(
                                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 1),
                                                color: Colors.transparent,
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                                                  child: Column(
                                                    children: <Widget>[
                                                      Container(
                                                        margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.only(
                                                            topLeft: Radius.circular(0),
                                                            bottomRight: Radius.circular(0),
                                                            bottomLeft: Radius.circular(0),
                                                            topRight: Radius.circular(0),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: <Widget>[
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
                                                              height: 80,
                                                              width: 80,
                                                              child: CachedNetworkImage(
                                                                imageUrl: user['horoscope_image_url'],
                                                                placeholder: (context, url) => Image.asset('assets/images/photo.png', fit: BoxFit.contain),
                                                                errorWidget: (context, url, error) => Image.asset('assets/images/photo.png', fit: BoxFit.contain),
                                                                fit: BoxFit.contain,
                                                                width: 80,
                                                                height: 80,
                                                              ),
                                                            ),
                                                            Flexible(
                                                              flex: 2,
                                                              child: Padding(
                                                                padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: <Widget>[
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: <Widget>[
                                                                        Container(
                                                                          width: MediaQuery.of(context).size.width / 2,
                                                                          child: Text(
                                                                            user['name'] ?? "",
                                                                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                                                                          ),
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                          children: <Widget>[
                                                                            Text(
                                                                              user['chat_time'] == null || user['chat_time'] == 'null' ? "" : formatChatTime(user['chat_time']),
                                                                              style: GoogleFonts.poppins(color: Color(0xff03A0E3), fontWeight: FontWeight.w400, fontSize: 14),
                                                                            ),
                                                                            const SizedBox(width: 5),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: <Widget>[
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                          child: Text(
                                                                            user['chat_message'] == null || user['chat_message'] == 'null' ? "" : user['chat_message'],
                                                                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w400),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(width: 5),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                createChatroomAndStartConversation(
                                                  user['chat_id'],
                                                  user['name'],
                                                  user['id'].toString(),
                                                  user['horoscope_image_url'].toString(),
                                                );
                                              },
                                            );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : wifi_sttus == -1
                        ? CircularProgressIndicator()
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  height: 200,
                                  width: 200,
                                  padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
                                  child: Image.asset("assets/images/nowifi.png", fit: BoxFit.contain),
                                ),
                                Text(
                                  "Please #getsocial! You are not connected.",
                                  style: GoogleFonts.poppins(color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 15),
                                ),
                                Text(
                                  "Please check your Wi-Fi connection.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w400, fontSize: 15),
                                ),
                              ],
                            ),
                          );
              } else {
                wifi_sttus = 0;
                connected_wifi = "gdtg@@@@";

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        height: 200,
                        width: 200,
                        padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
                        child: Image.asset("assets/images/nowifi.png", fit: BoxFit.contain),
                      ),
                      Text(
                        "Please #getsocial! You are not connected.",
                        style: GoogleFonts.poppins(color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 20),
                      ),
                      Text(
                        "Please check your Wi-Fi connection.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w400, fontSize: 20),
                      ),
                    ],
                  ),
                );
              }
            },
          ),*/
          bottomNavigationBar: Container(
              color: const Color(0xfff5f5f5),
              height: 80,
              // padding: EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                //crossAxisAlignment: CrossAxisAlignment.s,
                children: [
                  // ignore: deprecated_member_use
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        //  splashColor: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatListnew("1")));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              iconSize: 24,
                              color: Colors.grey,
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatListnew("1")));
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/chat.svg',
                                colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                              ),
                            ), // <-- Icon
                            const Text(
                              "Chats",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        // splashColor: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList_befhistoryid("2")));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              color: const Color(0xff03A0E3),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList_befhistoryid("2")));
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/social-match.svg',
                                colorFilter: const ColorFilter.mode(const Color(0xff03A0E3), BlendMode.srcIn),
                              ),
                            ),
                            const Text(
                              "Social Match",
                              style: TextStyle(color: const Color(0xff03A0E3), fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        // splashColor: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventsList()));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventsList()));
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/social-event.svg',
                                colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                              ),
                            ),
                            const Text(
                              "Social Events",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        // splashColor: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventsList()));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              height: 53,
                              width: 53,
                              child: IconButton(
                                onPressed: () {
                                  bool isConnectedToConfiguredWifi = Provider.of<NetworkService>(context, listen: false).wifiName.toString().replaceAll('"', '') == config_wifi;
                                  if (isConnectedToConfiguredWifi == true) {
                                    _launchUrl();
                                  }

                                  /*   Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => ReviewScreen(
                                        "https://www.google.com/search?q=my+business&mat=CYnmlD3i_GwwEkwBezTaAax5KIUml55b5P-vVH-yOxpuBb_Vup80YYH4BwSeaPddvjtIb7UdzJC5wemuue4W-PSH7qRm6rpHRRh5-HeDg-ZfB6dKHdNVGggHBhoz3H860g&hl=en&authuser=0",
                                        1)));*/
                                },
                                icon: SvgPicture.asset(
                                  'assets/icons/socialreview.svg',
                                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                ),
                              ),
                            ),
                            const Text(
                              "Social Review",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ))),
    );
  }
}

class CustomShape extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    double height = size.height;
    double width = size.width;
    var path = Path();
    path.lineTo(0, height - 60);
    path.quadraticBezierTo(width / 2, height, width, height - 60);
    path.lineTo(width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

class ExpandableText extends StatefulWidget {
  const ExpandableText(
    this.text, {
    this.trimLines = 2,
  });

  final String text;
  final int trimLines;

  @override
  ExpandableTextState createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {
  bool _readMore = true;
  void _onTapLink() {
    setState(() => _readMore = !_readMore);
  }

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    final colorClickableText = const Color(0xff03A0E3);
    final widgetColor = Colors.black;
    TextSpan link = TextSpan(
        text: _readMore ? "... read more" : " read less",
        style: TextStyle(
          color: colorClickableText,
        ),
        recognizer: TapGestureRecognizer()..onTap = _onTapLink);
    Widget result = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints.hasBoundedWidth);
        final double maxWidth = constraints.maxWidth;
        // Create a TextSpan with data
        final text = TextSpan(
          text: widget.text,
        );
        // Layout and measure link
        TextPainter textPainter = TextPainter(
          text: link,
          //textDirection: TextDirection.rtl, //better to pass this from master widget if ltr and rtl both supported
          maxLines: widget.trimLines,
          ellipsis: '...',
        );
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final linkSize = textPainter.size;
        // Layout and measure text
        textPainter.text = text;
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final textSize = textPainter.size;
        // Get the endIndex of data
        int? endIndex;
        final pos = textPainter.getPositionForOffset(Offset(
          textSize.width - linkSize.width,
          textSize.height,
        ));
        endIndex = textPainter.getOffsetBefore(pos.offset);
        var textSpan;
        if (textPainter.didExceedMaxLines) {
          textSpan = TextSpan(
            text: _readMore ? widget.text.substring(0, endIndex) : widget.text,
            style: TextStyle(
              color: widgetColor,
            ),
            children: <TextSpan>[link],
          );
        } else {
          textSpan = TextSpan(
            text: widget.text,
          );
        }
        return RichText(
          softWrap: true,
          overflow: TextOverflow.clip,
          text: textSpan,
        );
      },
    );
    return result;
  }
}

class NetworkAwareAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  _NetworkAwareAppBarState createState() => _NetworkAwareAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NetworkAwareAppBarState extends State<NetworkAwareAppBar> {
  // final LocalStorage storage = LocalStorage('wifi');
  String config_wifi = "";

  @override
  void initState() {
    super.initState();

    retrieveWifiName();
  }

  Future<void> retrieveWifiName() async {
    print(Provider.of<NetworkService>(context).wifiName.toString().replaceAll('"', ''));
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/wifi_details'));
    request.body = json.encode({"wifi_name": Provider.of<NetworkService>(context).wifiName.toString().replaceAll('"', '')});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseBody);

        // Ensure that the 'data' field is present and contains 'wifi_name'
        if (responseData.containsKey('data') && responseData['data'] != null) {
          Map<String, dynamic> data = responseData['data'];
          if (data.containsKey('wifi_name') && data['wifi_name'] != null) {
            String wifiName = data['wifi_name'];
            String url_ = data['google_url'];
            dynamic shopid = data['id'];
            print('LOTRM Name: $wifiName');

            setState(() {
              config_wifi = wifiName;
            });

            /*  config_wifi = wifiName;
            shop_id = shopid;
            googlerul = url_;*/

            // Now you can use the WiFi name as needed
          } else {
            print('WiFi name not found or is null in the data');
          }
        } else {
          print('Data not found or is null in the response');
        }
      } else {
        print('Failed to retrieve WiFi name: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return getAppBottomView(context);
  }

  Widget _buildTitle(BuildContext context) {
    if (config_wifi.isEmpty) {
      return const Text(
        "Loading...",
        style: TextStyle(color: Color(0xff03A0E3)),
      );
    } else {
      bool isConnectedToConfiguredWifi = Provider.of<NetworkService>(context).wifiName.toString().replaceAll('"', '') == config_wifi;
      return Text(
        isConnectedToConfiguredWifi ? "Connected" : "Not Connected",
        style: TextStyle(color: isConnectedToConfiguredWifi ? Colors.green : Colors.red),
      );
    }
  }

  Widget getAppBottomView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 5, bottom: 10, top: 5),
      //height: 100, // Set a fixed height for the container
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Image.asset(
            "assets/images/confywhite.png",
            fit: BoxFit.contain,
            height: 58,
            color: Colors.white,
          ),
          Row(
            children: [
              PopupMenuButton(
                color: Colors.white,
                iconColor: Colors.white,
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: 'pro',
                      child: Text(
                        'My Profile',
                        style: TextStyle(color: Color(0xff03A0E3)),
                      ),
                    ),
                  ];
                },
                onSelected: (String value) {
                  if (value == 'pro') {
                    //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyProfilePage("1")));
                    bool isConnectedToConfiguredWifi = Provider.of<NetworkService>(context, listen: false).wifiName.toString().replaceAll('"', '') == config_wifi;
                    if (isConnectedToConfiguredWifi == true) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyProfilePage("1")));
                    }
                  }
                  print('You Click on popup menu item');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
