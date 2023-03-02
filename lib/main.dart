import 'package:flutter/material.dart';

import 'home_page.dart';

/// true - if you need to enable encryption for example app
bool shouldInitWithEncryption = false;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const  MaterialApp(
      home: HomePage(),
    );
  }
}