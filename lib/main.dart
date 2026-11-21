import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db.dart';
import 'core/key_store.dart';
import 'data/repo.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final key = await getOrCreateDbKey();
  final db = await openBaguetteDb(key);
  final repo = Repo(db);
  final settings = await repo.loadSettings();
  runApp(ProviderScope(
    overrides: [
      repoProvider.overrideWithValue(repo),
      initialSettingsProvider.overrideWithValue(settings),
    ],
    child: const BaguetteApp(),
  ));
}
