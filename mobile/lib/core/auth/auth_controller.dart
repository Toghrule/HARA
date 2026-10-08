import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_session.dart';
import 'session_storage.dart';
import 'token_source.dart';

/// Who is signed in (`null` = nobody) and how they stay signed in.
///
/// The server hands out a refresh token that works once: using it gives a new access token and a new
/// refresh token, and using an old one again signs the account out everywhere. So renewing must never
/// run twice at the same time — requests that need a token while a renewal is under way wait for that
/// same renewal ([_renewing]) instead of starting their own.
class AuthController extends StateNotifier<AuthSession?> implements TokenSource {
  AuthController(this._repository, this._storage, [AuthSession? initial]) : super(initial);

  /// Renew a little before the token dies so a request doesn't leave with one that expires on the way.
  static const _renewMargin = Duration(seconds: 60);

  final AuthRepository _repository;
  final SessionStorage _storage;

  Future<AuthSession?>? _renewing;

  bool get isSignedIn => state != null;

  Future<void> signIn({required String email, required String password}) async =>
      _start(await _repository.login(email: email, password: password));

  Future<void> registerOwner({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    required String restaurantName,
    required String address,
    String? restaurantPhoneNumber,
    String? description,
  }) async =>
      _start(await _repository.registerOwner(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        restaurantName: restaurantName,
        address: address,
        restaurantPhoneNumber: restaurantPhoneNumber,
        description: description,
      ));

  Future<void> registerStaff({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    required String restaurantId,
  }) async =>
      _start(await _repository.registerStaff(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        restaurantId: restaurantId,
      ));

  /// Signs out on this device right away, then tells the server so the refresh token stops working.
  /// Not hearing back from the server doesn't keep anyone signed in.
  Future<void> signOut() async {
    final session = state;
    await _forget();
    if (session == null) return;

    try {
      await _repository.logout(session.refreshToken);
    } catch (_) {
      // The token expires on its own.
    }
  }

  @override
  Future<String?> validAccessToken() async {
    final session = state;
    if (session == null) return null;
    if (!session.accessExpiresWithin(_renewMargin)) return session.accessToken;

    return (await _renew())?.accessToken;
  }

  @override
  Future<String?> refreshAccessToken() async => (await _renew())?.accessToken;

  Future<AuthSession?> _renew() => _renewing ??= _doRenew().whenComplete(() => _renewing = null);

  Future<AuthSession?> _doRenew() async {
    final current = state;
    if (current == null) return null;

    try {
      final next = await _repository.refresh(current.refreshToken);
      if (next == null) {
        // The server won't accept it any more (it expired, or the account was signed out elsewhere).
        await _forget();
        return null;
      }

      await _start(next);
      return next;
    } catch (_) {
      // No connection or server trouble: that says nothing about the session, so keep it and try again
      // on the next request. The old token may still be good for a moment.
      return current.accessExpiresWithin(Duration.zero) ? null : current;
    }
  }

  Future<void> _start(AuthSession session) async {
    if (!mounted) return;

    state = session;
    await _storage.write(session);
  }

  Future<void> _forget() async {
    if (mounted) state = null;
    await _storage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final sessionStorageProvider = Provider<SessionStorage>((ref) => const SecureSessionStorage());

/// Starts signed out; `main` overrides it with the session found on the device.
final authControllerProvider = StateNotifierProvider<AuthController, AuthSession?>(
  (ref) => AuthController(ref.watch(authRepositoryProvider), ref.watch(sessionStorageProvider)),
);
