import 'dart:convert';

import 'package:chatapp/screens/showevents.dart';
import 'package:chatapp/screens/socialmatch.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/loader.dart';
import '../main.dart';
import 'NetworkService.dart';
import 'chatlistnew.dart';

class EventsList extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<EventsList> {
  bool _isLoading = false;
  String? UserId = "";
  String evntdate = "";
  List<dynamic> activeUsersList = [];
  String shop_id = "";
  String googlerul = "";
  // final LocalStorage storage = new LocalStorage('wifi');
  String config_wifi = "emty";
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

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Handling a foreground message: ${message.messageId}');
        print('Notification Message: ${message.data}');

        final data = message.data;
        final title = data['title'] ?? '';
        final body = data['body'] ?? '';
        final imageUrl = data['image'] ?? '';
        // showNotificationDialog(title, body, imageUrl);
        //  NotificationService().showNotification(title: title, body: body);
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
                        return SizedBox(
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
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    activeUsersList = [];
    super.initState();
    registerForNotifications();
    retrive();
    /*_streamSubscription = _streamController.stream.listen((_) {
      _initConnectivity();
      // Call your method here whenever an event is added to the stream
    });*/
  }

  Future retrive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    print(UserId.toString());
    _fetchListItems(UserId);
    // await storage.ready;
    String? name = localStorage.getItem('wifiname');
    String? ssid = localStorage.getItem('SSID');
    config_wifi = localStorage.getItem('wifiname') ?? '';
    googlerul = localStorage.getItem('url') ?? '';

    // _startTimer();
  }

  _fetchListItems(dynamic userid) async {
    var request = http.Request('GET', Uri.parse('https://connfy.ragutis.com/api/get_social_events'));
    request.body = '''''';

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseString = await response.stream.bytesToString();
      Map<String, dynamic> responseData = json.decode(responseString);

      if (responseData.containsKey('data')) {
        setState(() {
          activeUsersList = responseData['data'];
        });
      } else {
        // Handle error if 'data' key is not found
        print("Error: 'data' key not found in the response");
      }
    } else {
      print(response.reasonPhrase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[loadUi(), _isLoading ? Loader(loadingTxt: 'Please wait..') : Container()],
    );
  }

  @override
  Widget loadUi() {
    return Scaffold(
        appBar: buildAppBar(),
        body: Padding(padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0), child: getHomePageBody(context)),
        bottomNavigationBar: SafeArea(
            child: Container(
                color: const Color(0xfff5f5f5),
                height: 80,
                // padding: EdgeInsets.all(5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                                color: Color(0xff03A0E3),
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatListnew("1")));
                                },
                                icon: SvgPicture.asset(
                                  'assets/icons/chat.svg',
                                  colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                ),
                              ),
                              const Text(
                                "Chats",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ), // <-- Text
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      child: Material(
                        color: const Color(0xfff5f5f5),
                        child: InkWell(
                          // splashColor: Colors.green,
                          onTap: () {
                            //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList("2")));
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                color: Colors.grey,
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList("2")));
                                },
                                icon: SvgPicture.asset(
                                  'assets/icons/social-match.svg',
                                  colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                ),
                              ),
                              const Text(
                                "Social Match",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ), // <-- Text
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
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
                                onPressed: () {},
                                icon: SvgPicture.asset(
                                  'assets/icons/social-event.svg',
                                  colorFilter: ColorFilter.mode(Color(0xff03A0E3), BlendMode.srcIn),
                                ),
                              ),
                              const Text(
                                "Social Events",
                                style: TextStyle(color: Color(0xff03A0E3), fontSize: 12),
                              ), // <-- Text
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
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
                                height: 47,
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

                    /*  Container(
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
                           //   _launchUrl();
                            */ /*  Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ReviewScreen(
                                      "https://www.google.com/search?q=my+business&mat=CYnmlD3i_GwwEkwBezTaAax5KIUml55b5P-vVH-yOxpuBb_Vup80YYH4BwSeaPddvjtIb7UdzJC5wemuue4W-PSH7qRm6rpHRRh5-HeDg-ZfB6dKHdNVGggHBhoz3H860g&hl=en&authuser=0",
                                      3)));*/ /*
                            },
                            icon: SvgPicture.asset(
                              'assets/icons/socialreview.svg',
                              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
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
                )*/
                  ],
                ))));
  }

  getHomePageBody(BuildContext context) {
    return ListView.builder(
      itemCount: activeUsersList.length,
      itemBuilder: _getItemUI1,
      padding: const EdgeInsets.all(0.0),
    );
  }

  // First Task
/* Widget _getItemUI(BuildContext context, int index) {
   return new Text(_allCities[index].name);
 }*/
  AppBar buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Color(0xff03A0E3),
      titleSpacing: 0,
      leading: const Icon(
        Icons.arrow_back,
        color: Color(0xff03A0E3),
      ),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Social Events',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _getItemUI1(BuildContext context, int index) {
    DateFormat inputFormat = DateFormat("dd-MM-yyyy HH:mm");
    DateFormat outputFormat = DateFormat("dd MMM yyyy");

    // Parse string to DateTime
    DateTime dateTime = inputFormat.parse(activeUsersList[index]['start_date']);
    print(outputFormat.format(dateTime));
    evntdate = outputFormat.format(dateTime).toString();
    List<String> dateParts = evntdate.split(' ');
    String day = dateParts[0];
    String month = dateParts[1].toUpperCase(); // Step 3: Convert month to uppercase
    String year = dateParts[2];

    // Step 4: Reassemble the string
    String result = "$day $month $year";
    print(result);
    return GestureDetector(
      child: Card(
        elevation: 5,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Column(
          //crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 150,
                  width: 150,
                  padding: const EdgeInsets.only(left: 0, top: 0),
                  child: Image.network(
                    activeUsersList[index]['cover_image'],
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  // color: Colors.white,
                  padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result,
                        style: GoogleFonts.poppins(
                          color: Color(0xff03A0E3),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 0,
                        ),
                      ),
                      // ignore: prefer_const_constructors
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Text(
                            activeUsersList[index]['title'],
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 15,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                              height: 0,
                            ),
                          )),
                      const SizedBox(
                        height: 5,
                      ),
                      /* Container(
                          width: 190,
                          child: Text(activeUsersList[index]['description'],
                              style: GoogleFonts.poppins(
                                color: Colors.black26,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ))),*/
                      Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: ReadMoreText(
                            activeUsersList[index]['description'],
                            trimMode: TrimMode.Line,
                            trimLines: 2,
                            colorClickableText: Color(0xff03A0E3),
                            trimCollapsedText: 'Show more',
                            trimExpandedText: 'Show less',
                            style: GoogleFonts.poppins(
                              color: Colors.black26,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            moreStyle: GoogleFonts.poppins(
                              color: Color(0xff81cff1),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            lessStyle: GoogleFonts.poppins(
                              color: Color(0xff81cff1),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ))
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      onTap: () {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => WebViewScreen(
                      activeUsersList[index]['url'],
                    )));
      },
    );
  }
}
