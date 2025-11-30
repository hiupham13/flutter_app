import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hôm Nay Ăn Gì?'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Dashboard Screen',
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

