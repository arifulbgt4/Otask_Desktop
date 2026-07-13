import 'package:flutter/material.dart';

void main() {
  runApp(const OTaskApp());
}

class OTaskApp extends StatelessWidget {
  const OTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTask',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('OTask mobile bootstrap')),
      ),
    );
  }
}
