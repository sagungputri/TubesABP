import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async'; 

import 'onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
      await dotenv.load(fileName: ".env");
      print(".env file loaded successfully."); 
  } catch (e) {
      print("Error loading .env file: $e"); 
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(      
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}