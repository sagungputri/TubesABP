import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tubes1/constants.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showPassword = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Back",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Log in to continue",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            const Text("Email"),
            const SizedBox(height: 6),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Constants.primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text("Password"),
            const SizedBox(height: 6),
            TextField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Constants.primaryColor),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // aksiny
                  final email = emailController.text;
                  final pass = passwordController.text;
                  if (email.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email dan password wajib diisi.'),
                      ),
                    );
                  } else {
                    // simulasinyaa
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Login berhasil')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Sign In",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: "Sign up",
                      style: const TextStyle(
                        color: Constants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = goToRegister,
                    ),
                    const TextSpan(text: " now."),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
