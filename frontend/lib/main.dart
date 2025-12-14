import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/config.dart';

import 'dart:io';

void main() {
  String baseUrl = 'http://localhost:8001';
  try {
    if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:8001';
    }
  } catch (e) {
    // Platform checking not supported on Web, or other error. Default to localhost is fine for Web.
  }

  // Default to dev if ran directly
  AppConfig.init(
    environment: Environment.dev,
    apiBaseUrl: baseUrl, 
  );
  runApp(const ProviderScope(child: DBillerApp()));
}

class DBillerApp extends ConsumerWidget {
  const DBillerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'dBiller',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // lock to minimal light theme
      routerConfig: router,
    );
  }
}
