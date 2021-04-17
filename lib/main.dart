import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';
import 'screens/main_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        iconTheme: IconThemeData(color: Colors.orange),
        textTheme: GoogleFonts.montserratTextTheme(),
        primaryTextTheme: TextTheme(
          headline6: TextStyle(color: Colors.black),
        ),
        primarySwatch: Colors.orange,
      ),
      home: ScrollConfiguration(
        behavior: MyBehavior(),
        child: MainPage(),
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
