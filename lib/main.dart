import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'data/db/db_files.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final support = await getApplicationSupportDirectory();
  final files = DbFiles(Directory(p.join(support.path, 'db')))
    ..root.createSync(recursive: true)
    ..cleanupStray();
  final info = await PackageInfo.fromPlatform();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        dbFilesProvider.overrideWithValue(files),
        appVersionProvider.overrideWithValue(info.version),
        prefsProvider.overrideWithValue(prefs),
      ],
      child: const ScryfallApp(),
    ),
  );
}

class ScryfallApp extends ConsumerWidget {
  const ScryfallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Scryfall Offline Search',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B4FA3)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B4FA3),
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
