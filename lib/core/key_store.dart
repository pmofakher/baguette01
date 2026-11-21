import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// کلید رمزگذاری دیتابیس (SQLCipher) در Android Keystore نگهداری می‌شود.
Future<String> getOrCreateDbKey() async {
  var key = await _storage.read(key: 'db_key');
  if (key == null) {
    final r = Random.secure();
    key = base64UrlEncode(List<int>.generate(32, (_) => r.nextInt(256)));
    await _storage.write(key: 'db_key', value: key);
  }
  return key;
}
