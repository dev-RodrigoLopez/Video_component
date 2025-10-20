import 'package:flutter/material.dart';
import 'package:video_component/home_screen.dart';
import 'camera_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Recorder',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
