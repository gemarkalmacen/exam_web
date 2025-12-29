import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool("isLoggedIn") ?? false;
    return loggedIn ? const HomeScreen() : const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Web App",
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: checkLogin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data!;
        },
      ),
    );
  }
}
