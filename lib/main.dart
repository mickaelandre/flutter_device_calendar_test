import 'package:flutter/material.dart';
import 'package:flutter_app_calendar_test/homepage.dart';
import 'controller/calendarController.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'Device Calendar Example',
      home:  MyApp2(),
    );
  }
}