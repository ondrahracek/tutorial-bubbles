import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  runApp(const TutorialBubblesExampleApp());
}

class TutorialBubblesExampleApp extends StatelessWidget {
  const TutorialBubblesExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutorial Bubbles Example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Tutorial Bubbles Example'),
        ),
        body: const Center(
          child: TutorialBubble(
            backgroundColor: Colors.blueAccent,
            child: Text('Tutorial bubbles package scaffold'),
          ),
        ),
      ),
    );
  }
}

