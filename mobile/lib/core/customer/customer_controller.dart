import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session.dart';
import '../auth/token_source.dart';
import '../constants/app_constants.dart';
import 'customer_session.dart';
import 'google_sign_in_service.dart';

/// Where the customer's session lives on the device between launches (separate from a restaurant account's).
abstract interface class CustomerSessionStorage {
  Future<CustomerSession?> read();

  Future<void> write(CustomerSession session);

  Future<void> clear();
}

class SecureCustomerSessionStorage implements CustomerSessionStorage {
  const SecureCustomerSessionStorage([this._storage = const FlutterSecureStorage()]);

  static const _key = 'customer_session';

  final FlutterSecureStorage _storage;

  @override
  Future<CustomerSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);

      return raw == null ? null : CustomerSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(CustomerSession session) async {
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
      // Nothing to forget.
    }
  }
}

/// Talks to the customer's account endpoints with its own plain client (no automatic sign-in header), because these are the calls that
/// create, renew and end the session.
class CustomerRepository {
  CustomerRepository([Dio? dio]) : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  final Dio _dio;

  /// Trades the token Google (through Firebase) gave for HARA's own session.
  Future<CustomerSession> signInWithGoogle(String idToken) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/auth/google', data: {'idToken': idToken});

    return CustomerSession.fromApi(response.data!);
  }

  /// Deletes the customer's account and reviews.
  Future<void> deleteAccount(String accessToken) async {
    await _dio.delete<void>('/api/customer', options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
  }
}

/// Who is signed in as a customer (`null` = nobody) and how they stay signed in. Works like the restaurant side's [AuthController]: the
/// refresh token works once, so renewing never runs twice at the same time.
class CustomerController extends StateNotifier<CustomerSession?> implements TokenSource {
  CustomerController(this._repository, this._auth, this._storage, this._google, [CustomerSession? initial]) : super(initial);

  static const _renewMargin = Duration(seconds: 60);

  final CustomerRepository _repository;
  final AuthRepository _auth;
  final CustomerSessionStorage _storage;
  final GoogleSignInService _google;

  Future<CustomerSession?>? _renewing;

  bool get isSignedIn => state != null;

  bool get canSignIn => _google.isAvailable;

  /// Asks for a Google account and signs in with it. Returns `false` when the person closed the window. Throws if it went wrong.
  Future<bool> signIn() async {
    final idToken = await _google.signIn();
    if (idToken == null) return false;

    await _start(await _repository.signInWithGoogle(idToken));

    return true;
  }

  /// Signs out on this device right away, then tells the server so the refresh token stops working.
  Future<void> signOut() async {
    final session = state;
    await _forget();
    await _google.signOut();
    if (session == null) return;

    try {
      await _auth.logout(session.auth.refreshToken);
    } catch (_) {
      // The token expires on its own.
    }
  }

  /// Deletes the account on the server (and the reviews with it), then forgets everything here. Throws if the server refused.
  Future<void> deleteAccount() async {
    final token = await validAccessToken();
    if (token == null) return;

    await _repository.deleteAccount(token);
    await _forget();
    await _google.signOut();
  }

  @override
  Future<String?> validAccessToken() async {
    final session = state;
    if (session == null) return null;
    if (!session.auth.accessExpiresWithin(_renewMargin)) return session.auth.accessToken;

    return (await _renew())?.auth.accessToken;
  }

  @override
  Future<String?> refreshAccessToken() async => (await _renew())?.auth.accessToken;

  Future<CustomerSession?> _renew() => _renewing ??= _doRenew().whenComplete(() => _renewing = null);

  Future<CustomerSession?> _doRenew() async {
    final current = state;
    if (current == null) return null;

    try {
      final AuthSession? next = await _auth.refresh(current.auth.refreshToken);
      if (next == null) {
        // The server won't accept it any more (it expired, or the account is gone).
        await _forget();
        return null;
      }

      final renewed = current.withAuth(next);
      await _start(renewed);
      return renewed;
    } catch (_) {
      // No connection or server trouble says nothing about the session: keep it and try again with the next request.
      return current.auth.accessExpiresWithin(Duration.zero) ? null : current;
    }
  }

  Future<void> _start(CustomerSession session) async {
    if (!mounted) return;

    state = session;
    await _storage.write(session);
  }

  Future<void> _forget() async {
    if (mounted) state = null;
    await _storage.clear();
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) => CustomerRepository());

final customerSessionStorageProvider = Provider<CustomerSessionStorage>((ref) => const SecureCustomerSessionStorage());

/// Starts signed out; `main` overrides it with the session found on the device.
final customerControllerProvider = StateNotifierProvider<CustomerController, CustomerSession?>(
  (ref) => CustomerController(
    ref.watch(customerRepositoryProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(customerSessionStorageProvider),
    ref.watch(googleSignInServiceProvider),
  ),
);
