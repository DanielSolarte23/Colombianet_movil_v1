import 'package:flutter/material.dart';
import 'package:colombianet_app/views/login.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Colombianet app',
      home: Scaffold(
        body: login(),
      ),
    );
  }
}