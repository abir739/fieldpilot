import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: FieldPilotApp()));
}

class FieldPilotApp extends StatelessWidget {
  const FieldPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldPilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const HomeScreen(),
    );
  }
}
