import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: SelectableText(snapshot.error.toString())),
            ),
          );
        }
        return MultiProvider(
          providers: const [],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'UniNotes Admin',
            home: const Scaffold(
              body: Center(child: Text('UniNotes Admin')),
            ),
          ),
        );
      },
    );
  }
}
