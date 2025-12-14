import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config.dart';
import 'main.dart'; 

void main() {
  // Replace with actual production URL
  AppConfig.init(
    environment: Environment.prod,
    apiBaseUrl: 'https://dbiller-production.up.railway.app', 
  );
  runApp(const ProviderScope(child: DBillerApp()));
}
