import 'dart:convert';

import 'package:chatapp/helper/shared_preference.dart';
import 'package:chatapp/screens/chatRoom.dart';
import 'package:chatapp/screens/chatlist.dart';
import 'package:chatapp/services/auth.dart';
import 'package:chatapp/services/database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../buttons/roundedbutton.dart';
import '../constant.dart';

class SignUp extends StatefulWidget {
  final Function toggle;
  SignUp(this.toggle);
  //const SignUp(void Function() toggleView, {Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool isLoading = false;
  DatabaseMethods databaseMethods = DatabaseMethods();
  AuthService authService = AuthService();
  HelperFunctions helperFunctions = HelperFunctions();
  final formkey = GlobalKey<FormState>();
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  SignMeUP() {
    if (formkey.currentState != null) {
      formkey.currentState?.validate();
    }

    {
      setState(() {
        isLoading = true;
      });

      /*  Map<String, String> userDataMap = {
          "userName": userNameTextEditingController.text,
          "userEmail": emailTextEditingController.text,
          'isOnline': true.toString(),
          'lastActive': DateTime.now().toString(),
        };
        databaseMethods.addUserInfo(userDataMap);
        HelperFunctions.saveUserLoggedInSharedPreference(true);
        HelperFunctions.saveUserEmailSharedPreference(
            emailTextEditingController.text);
        HelperFunctions.saveUserNameSharedPreference(
            userNameTextEditingController.text);*/

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatRoom()));
      authService.signUpWithEmailAndPassword(emailTextEditingController.text, passwordTextEditingController.text).then((val) {
        print("${val.uid}");
        setState(() {
          isLoading = false;
        });
        if (val != null) {
          Map<String, String> userDataMap = {
            "userName": userNameTextEditingController.text,
            "userEmail": emailTextEditingController.text,
            'isOnline': true.toString(),
            'lastActive': DateTime.now().toString(),
            'uid': val.uid.toString(),
          };
          databaseMethods.addUserInfo(userDataMap);
          HelperFunctions.saveUserLoggedInSharedPreference(true);
          HelperFunctions.saveUserEmailSharedPreference(emailTextEditingController.text);
          HelperFunctions.saveUserNameSharedPreference(userNameTextEditingController.text);

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatRoom()));
        }
      });
    }
  }

  doRegistration(String mobile_device_id, String nick_name, String dob, String gender, String email) async {
    var headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> data = {
      "status": 0,
      "mobile_device_id": "JPASSFDDGD656546fggM",
      "ssid": "FTTH",
      "nick_name": nick_name,
      "dob": dob,
      "gender": gender,
      "email": email,
      "social_media_login": 0
    };

    try {
      var request = http.Request('POST', Uri.parse('https://connfy.ragutis.com/api/create_user'));
      request.body = json.encode(data);
      print(json.encode(data));

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 202) {
        setState(() {
          isLoading = false;
        });
        String jsonData = await response.stream.bytesToString();
        Map<String, dynamic> responseData = jsonDecode(jsonData);
        print(responseData);

        // Handle the parsed JSON data
        parseResponseData(responseData);
        //   showSnakBar("Account Created Successfully");
        // parseUserData(jsonData);
      } else {
        setState(() {
          isLoading = false;
        });

        print(response.reasonPhrase);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error creating account: $e");

      print('$e');
    }
  }

  void parseResponseData(Map<String, dynamic> userData) {
    // Extract data from responseData and handle it as needed
    // For example:
    String userId = userData['user_id'];
    String status = userData['status'];

    // addItemsToLocalStorage(userId, userName, email, phone, roleName, gender, age, status);

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList(userId)));
    // Access more fields as needed

    print('User ID: $userId');
    print('Status: $status');
    // Print or handle more fields as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Container(
              child: const Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        height: 60,
                      ),
                      const Image(
                        height: 194,
                        width: 200,
                        image: AssetImage("assets/images/logo.png"),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      TextFormField(
                        validator: (val) {
                          return val!.isEmpty || val.length < 4 ? "Username must contain more than 4 characters" : null;
                        },
                        controller: userNameTextEditingController,
                        decoration: kTextFieldDecoration.copyWith(hintText: 'username'),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        validator: (val) {
                          return val!.isEmpty || val.length > 6 ? null : "Password should contain minimum 7 characters";
                        },
                        obscureText: true,
                        controller: passwordTextEditingController,
                        decoration: kTextFieldDecoration.copyWith(hintText: 'password'),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        obscureText: true,
                        decoration: kTextFieldDecoration.copyWith(hintText: 'confirm password'),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        validator: (val) {
                          return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val!) ? null : "Provide a valid Email ID";
                        },
                        controller: emailTextEditingController,
                        decoration: kTextFieldDecoration.copyWith(hintText: 'email'),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Container(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: const Text("Forgot Password?"),
                          )),
                      const SizedBox(
                        height: 8,
                      ),
                      Container(
                          child: RoundedButton(
                        onPressed: () {
                          SignMeUP();
                        },
                        text: 'Sign Up',
                        colour: Colors.teal.shade400,
                      )),
                      Row(children: <Widget>[
                        Container(
                          padding: const EdgeInsets.only(left: 60),
                          child: const Text("Already have account?"),
                        ),
                        Container(
                          alignment: Alignment.bottomCenter,
                          child: TextButton(
                            child: const Text(
                              "LogIn",
                              style: kSendButtonTextStyle,
                            ),
                            onPressed: () {
                              widget.toggle();
                            },
                          ),
                        )
                      ])
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
