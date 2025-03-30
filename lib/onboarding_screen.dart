import 'package:flutter/material.dart';
import 'constants.dart';
import 'pages/page_landing.dart';
import 'pages/page_welcome.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isActive ? 20 : 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Constants.primaryColor,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView(
            controller: _controller,
            onPageChanged: _onPageChanged,
            children: const [PageLanding(), PageWelcome()],
          ),
          Positioned(
            bottom: 40,
            child: Row(
              children: List.generate(
                2,
                (index) => _indicator(_currentPage == index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
