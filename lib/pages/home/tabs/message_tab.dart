import 'package:flutter/material.dart';

class MessageTab extends StatelessWidget {
  const MessageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
      ),
      body: const Center(
        child: Text(
          '消息内容',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
