import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:tubes1/pages/register_page.dart';

class PageWelcome extends StatelessWidget {
  const PageWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Image.asset(
              'assets/images/logo-kita.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 40),

          const Text(
            'Smarter Way to Read News',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

        
          const Text(
            'Quickly catch up with AI-generated\nsummaries from trusted news sources.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                //navigasii ke signin
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Sign In", style: TextStyle(fontSize: 16)),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Constants.primaryColor, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Register",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
