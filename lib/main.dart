import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'package:tubes1/pages/news_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   home: const OnboardingScreen(),
    //   debugShowCheckedModeBanner: false,
    // );
    return MaterialApp(
      home: NewsScreen(), // Langsung arahkan ke NewsScreen
      debugShowCheckedModeBanner: false,
    );
  }
}
