import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The request an owner made to reset a forgotten password. [secret] is what proves a later "check" or "set the new
/// password" comes from the phone that asked, so it is kept like a password.
class PasswordResetTicket {
  const PasswordResetTicket({required this.requestId, required this.secret, required this.email});

  factory PasswordResetTicket.fromJson(Map<String, dynamic> json) => PasswordResetTicket(
        requestId: json['requestId'] as String,
        secret: json['secret'] as String,
        email: json['email'] as String,
      );

  final String requestId;
  final String secret;

  /// The email the request was made for, shown while waiting.
  final String email;

  Map<String, Object?> toJson() => {'requestId': requestId, 'secret': secret, 'email': email};
}

/// Where the open reset request lives on the device, so closing the app while waiting for HARA loses nothing.
abstract interface class PasswordResetStorage {
  Future<PasswordResetTicket?> read();

  Future<void> write(PasswordResetTicket ticket);

  Future<void> clear();
}

/// Keeps the request in the platform's secure storage. Storage trouble never throws: the owner simply has to ask again.
class SecurePasswordResetStorage implements PasswordResetStorage {
  const SecurePasswordResetStorage([this._storage = const FlutterSecureStorage()]);

  static const _key = 'password_reset';

  final FlutterSecureStorage _storage;

  @override
  Future<PasswordResetTicket?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;

      return PasswordResetTicket.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(PasswordResetTicket ticket) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(ticket.toJson()));
    } catch (_) {
      // The request still works until the app is closed.
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

final passwordResetStorageProvider = Provider<PasswordResetStorage>((ref) => const SecurePasswordResetStorage());
