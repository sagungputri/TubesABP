import 'package:flutter/material.dart';
import 'package:tubes1/constants.dart';

class PageLanding extends StatelessWidget {
  const PageLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 350,
            child: Image.asset('assets/images/landing-news.png'),
          ),
          const SizedBox(height: 40),
          Text(
            Constants.titleOne,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            Constants.descriptionOne,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
