import 'package:flutter/material.dart';
import 'package:rssleader_app/screens/news_screen.dart';

void main() {
  runApp(const RssReaderApp());
}

class RssReaderApp extends StatelessWidget {
  const RssReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const NewsScreen(),
    );
  }
}
