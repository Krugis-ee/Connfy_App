import 'dart:async';
import 'package:chatapp/AppColorCodes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

import '../buttons/user_chat.dart';
import '../util/ui_helper.dart';
import 'ChatProvider.dart';

class ChatHome extends StatefulWidget {
  const ChatHome({super.key});

  @override
  State<ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  TextEditingController chatController = TextEditingController();
  ScrollController scrollController = ScrollController();
  Timer? _fetchHealthDataTimer;
  late Future<void> futureHealthData;

  bool isFetching = false; // Flag to prevent multiple API calls
  Stream<QuerySnapshot>? chats;
  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(onAttach: (position) {
      var chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.scrollToBottom(scrollController);
    });


    // Initial call to authorize health permission and fetch data
    _fetchHealthData();

    // Set up the periodic timer to call the fetch function every 4 hours

  }

  // Function to authorize and fetch health data
  void _fetchHealthData() async {

  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed

    scrollController.dispose();
    chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gene',
          style: TextStyle(fontSize: 15),
        ),
        leading:   Image.asset(
          "assets/images/confywhite.png",
          fit: BoxFit.contain,
          height: 58,
          color: Colors.white,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: InkWell(
              onTap: () {

              },
              child:   Image.asset(
                "assets/images/confywhite.png",
                fit: BoxFit.contain,
                height: 58,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: Consumer<ChatProvider>(builder: (_, chatProvider, __) {
        return Padding(
          padding:
              const EdgeInsets.only(left: 18.0, right: 18, bottom: 36, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                  child: chatProvider.messages.isNotEmpty
                      ? UserChat(
                          scrollController: scrollController,
                        )
                      : Container()),
              SizedBox(
                height: 22,
              ),
              AbsorbPointer(
                absorbing: chatProvider.isAnswerLoading || isFetching,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onTap: () {
                          chatProvider.scrollToBottom(scrollController);
                        },
                        controller: chatController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.fromLTRB(16, 14, 16, 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: pSecondaryColor,
                                width: 1,
                              )),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: pSecondaryColor,
                                width: 1,
                              )),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: pSecondaryColor,
                                width: 1,
                              )),
                          hintText: "Ask me anything...",
                          hintStyle: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 17,
                              color: Color.fromRGBO(166, 163, 157, 1)),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        if (chatController.text.isNotEmpty && !isFetching) {
                          final connectionStatus =
                              await Connectivity().checkConnectivity();
                          if (connectionStatus == ConnectivityResult.none) {
                            UiHelper().showSnackBar(
                                context, 'Please enable internet connection');
                            return;
                          }

                          String question = chatController.text;
                          FocusManager.instance.primaryFocus?.unfocus();

                          // Add question to chat provider
                         // chatProvider.getChatAnswer(question);
                          chatController.clear();
                          chatProvider.scrollToBottom(scrollController);

                          // Set the fetching flag
                          isFetching = true;

                          // Fetch GPT answer for the question
                          //await chatProvider.getChatAnswer(question);
                          chatProvider.scrollToBottom(scrollController);

                          // Reset the fetching flag after API call
                          isFetching = false;

                          // Fetch Health Data
                          String? userUid =
                             ' await sharePreferenceProvider.retrieveUserUid()';
                          DateTime now = DateTime.now();
                          String today = DateFormat('yyyy-MM-dd').format(now);




                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: pSecondaryColor),
                          child: SvgPicture.asset(
                            'buttonArrow',
                            fit: BoxFit.none,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}
