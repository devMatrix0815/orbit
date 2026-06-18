import 'package:flutter/material.dart';

class MyCircles extends StatelessWidget {
  const MyCircles({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meine Kreise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.add))],
      ),
    );
  }
}
