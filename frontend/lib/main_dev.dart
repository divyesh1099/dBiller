import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config.dart';
import 'main.dart'; // Import the shared DBillerApp widget

void main() {
  AppConfig.init(
    environment: Environment.dev,
    apiBaseUrl: 'http://localhost:8001',
  );
  runApp(const ProviderScope(child: DBillerApp()));
}
