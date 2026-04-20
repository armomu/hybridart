import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
      ),
      body: const Center(
        child: Text(
          '首页内容',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
