import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập ban đầu'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Onboarding Screen',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            Text('Coming Soon...'),
          ],
        ),
      ),
    );
  }
}

