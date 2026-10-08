import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

/// Where the signed-in session lives on the device between launches.
abstract interface class SessionStorage {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

/// Keeps the session in the platform's secure storage (Keychain / Keystore), since the refresh token
/// is as good as a password for weeks. Storage trouble never throws: the person is simply treated as
/// signed out, or stays signed in for the current run only.
class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage([this._storage = const FlutterSecureStorage()]);

  static const _key = 'session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;

      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(session.toJson()));
    } catch (_) {
      // Still signed in for this run.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Nothing more to do.
    }
  }
}
