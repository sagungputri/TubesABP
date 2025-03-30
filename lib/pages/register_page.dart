import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Let’s Get Started!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),

              const Text(
                "Create an account to get all features",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 32),

              const Text("Email"),
              const SizedBox(height: 6),
              TextField(
                decoration: InputDecoration(
                  hintText: "Email",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Constants.primaryColor),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text("Full Name"),
              const SizedBox(height: 6),
              TextField(
                decoration: InputDecoration(
                  hintText: "Full Name",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Constants.primaryColor),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text("Password"),
              const SizedBox(height: 6),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Constants.primaryColor),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: "Log in",
                        style: const TextStyle(
                          color: Constants.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                //navigasi signin
                              },
                      ),
                      const TextSpan(text: " now."),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    //navigasi regis
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Create an account",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text.rich(
                  TextSpan(
                    text: "By creating an account, you agree to our\n",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    children: [
                      TextSpan(
                        text: "Terms of Service",
                        style: const TextStyle(
                          color: Constants.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: " and "),
                      TextSpan(
                        text: "Privacy Policy",
                        style: const TextStyle(
                          color: Constants.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: "."),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
