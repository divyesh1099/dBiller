import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/config.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  String baseUrl;
  Environment env;

  if (kReleaseMode) {
    // Production Mode
    baseUrl = AppConfig.productionApiUrl;
    env = Environment.prod;
  } else {
    // Development Mode
    baseUrl = 'http://localhost:8001';
    env = Environment.dev;
    try {
      if (Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:8001';
      }
    } catch (e) {
      // Platform checking not supported on Web or other error
    }
  }

  AppConfig.init(
    environment: env,
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
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
