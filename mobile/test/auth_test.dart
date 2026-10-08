import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/auth/auth_controller.dart';
import 'package:hara/core/auth/auth_repository.dart';
import 'package:hara/core/auth/auth_session.dart';
import 'package:hara/core/auth/session_storage.dart';
import 'package:hara/core/network/api_client.dart';

AuthSession _session({
  String access = 'access-1',
  String refresh = 'refresh-1',
  Duration expiresIn = const Duration(minutes: 30),
  List<String> roles = const ['Owner'],
}) =>
    AuthSession(
      accessToken: access,
      accessExpiresAt: DateTime.now().add(expiresIn),
      refreshToken: refresh,
      roles: roles,
    );

class _MemoryStorage implements SessionStorage {
  AuthSession? saved;

  @override
  Future<AuthSession?> read() async => saved;

  @override
  Future<void> write(AuthSession session) async => saved = session;

  @override
  Future<void> clear() async => saved = null;
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository();

  final List<String> refreshCalls = [];
  final List<String> logoutCalls = [];

  AuthSession? Function(String refreshToken)? onRefresh;
  Object? refreshError;
  Object? logoutError;
  AuthSession loginResult = _session(access: 'login-access', refresh: 'login-refresh');

  /// Lets a test hold the renewal open to prove several requests share it.
  Completer<void>? refreshGate;

  @override
  Future<AuthSession> login({required String email, required String password}) async => loginResult;

  @override
  Future<AuthSession?> refresh(String refreshToken) async {
    refreshCalls.add(refreshToken);
    await refreshGate?.future;
    if (refreshError != null) throw refreshError!;

    return onRefresh!(refreshToken);
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls.add(refreshToken);
    if (logoutError != null) throw logoutError!;
  }
}

/// Answers HTTP requests from a script, remembering what was asked.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.respond);

  final int Function(RequestOptions options) respond;
  final List<RequestOptions> seen = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    seen.add(options);

    return ResponseBody.fromString(jsonEncode({'ok': true}), respond(options), headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _MemoryStorage storage;
  late _FakeAuthRepository repository;

  AuthController controller([AuthSession? initial]) => AuthController(repository, storage, initial);

  setUp(() {
    storage = _MemoryStorage();
    repository = _FakeAuthRepository();
  });

  group('AuthSession', () {
    test('survives being written to the device and read back', () {
      final original = _session(roles: ['Staff']);
      final copy = AuthSession.fromJson(original.toJson());

      expect(copy.accessToken, original.accessToken);
      expect(copy.refreshToken, original.refreshToken);
      expect(copy.roles, ['Staff']);
      expect(copy.accessExpiresAt.difference(original.accessExpiresAt).inSeconds.abs(), lessThan(1));
      expect(copy.isStaff, isTrue);
      expect(copy.isOwner, isFalse);
    });

    test('reads the API response', () {
      final session = AuthSession.fromApi({
        'token': 'jwt',
        'expiresAtUtc': '2026-10-08T11:57:01.5758684+00:00',
        'refreshToken': 'rt',
        'roles': ['Owner'],
      });

      expect(session.accessToken, 'jwt');
      expect(session.refreshToken, 'rt');
      expect(session.isOwner, isTrue);
    });

    test('knows when the access token is about to die', () {
      expect(_session(expiresIn: const Duration(minutes: 10)).accessExpiresWithin(const Duration(seconds: 60)), isFalse);
      expect(_session(expiresIn: const Duration(seconds: 30)).accessExpiresWithin(const Duration(seconds: 60)), isTrue);
      expect(_session(expiresIn: const Duration(minutes: -1)).accessExpiresWithin(Duration.zero), isTrue);
    });
  });

  group('signing in and out', () {
    test('signing in keeps the session in memory and on the device', () async {
      final auth = controller();
      await auth.signIn(email: 'a@b.az', password: 'x');

      expect(auth.state?.accessToken, 'login-access');
      expect(storage.saved?.refreshToken, 'login-refresh');
      expect(auth.isSignedIn, isTrue);
    });

    test('signing out clears both and tells the server to end the session', () async {
      final auth = controller(_session(refresh: 'rt-9'));
      storage.saved = auth.state;
      await auth.signOut();

      expect(auth.state, isNull);
      expect(storage.saved, isNull);
      expect(repository.logoutCalls, ['rt-9']);
    });

    test('signing out works with no connection too', () async {
      repository.logoutError = DioException(requestOptions: RequestOptions(path: '/x'));
      final auth = controller(_session());
      storage.saved = auth.state;
      await auth.signOut();

      expect(auth.state, isNull);
      expect(storage.saved, isNull);
    });
  });

  group('keeping the session alive', () {
    test('a fresh token is used as it is, with no renewal', () async {
      final auth = controller(_session(access: 'still-good'));

      expect(await auth.validAccessToken(), 'still-good');
      expect(repository.refreshCalls, isEmpty);
    });

    test('nobody signed in means no token', () async {
      expect(await controller().validAccessToken(), isNull);
      expect(repository.refreshCalls, isEmpty);
    });

    test('a token about to expire is renewed first, and the new session is kept', () async {
      repository.onRefresh = (_) => _session(access: 'access-2', refresh: 'refresh-2');
      final auth = controller(_session(expiresIn: const Duration(seconds: 20)));

      expect(await auth.validAccessToken(), 'access-2');
      expect(auth.state?.refreshToken, 'refresh-2');
      expect(storage.saved?.refreshToken, 'refresh-2');
    });

    test('several requests at once share one renewal (a refresh token only works once)', () async {
      repository
        ..refreshGate = Completer<void>()
        ..onRefresh = (_) => _session(access: 'access-2', refresh: 'refresh-2');
      final auth = controller(_session(expiresIn: const Duration(seconds: 20)));

      final results = [for (var i = 0; i < 5; i++) auth.validAccessToken()];
      await Future<void>.delayed(Duration.zero);
      repository.refreshGate!.complete();

      expect(await Future.wait(results), everyElement('access-2'));
      expect(repository.refreshCalls, ['refresh-1'], reason: 'one refresh, not five');
    });

    test('after a renewal finishes, the next one can start', () async {
      var n = 1;
      repository.onRefresh = (_) {
        n++;
        return _session(access: 'access-$n', refresh: 'refresh-$n');
      };
      final auth = controller(_session(expiresIn: const Duration(seconds: 20)));

      await auth.refreshAccessToken();
      await auth.refreshAccessToken();

      expect(repository.refreshCalls, ['refresh-1', 'refresh-2']);
    });

    test('a refresh token the server rejects signs the person out', () async {
      repository.onRefresh = (_) => null;
      final auth = controller(_session(expiresIn: const Duration(seconds: 20)));
      storage.saved = auth.state;

      expect(await auth.validAccessToken(), isNull);
      expect(auth.state, isNull);
      expect(storage.saved, isNull);
    });

    test('no connection while renewing keeps the person signed in', () async {
      repository.refreshError = DioException(requestOptions: RequestOptions(path: '/x'));
      final auth = controller(_session(expiresIn: const Duration(seconds: 20), access: 'old-but-valid'));
      storage.saved = auth.state;

      // The old token still has a few seconds, so it is still handed out…
      expect(await auth.validAccessToken(), 'old-but-valid');
      // …and the session is untouched, so the next request can try again.
      expect(auth.state, isNotNull);
      expect(storage.saved, isNotNull);
    });

    test('no connection with an already expired token gives no token but keeps the session', () async {
      repository.refreshError = DioException(requestOptions: RequestOptions(path: '/x'));
      final auth = controller(_session(expiresIn: const Duration(minutes: -5)));

      expect(await auth.validAccessToken(), isNull);
      expect(auth.state, isNotNull);
    });
  });

  group('requests to the restaurant-side API', () {
    ApiClient clientWith(AuthController auth, _ScriptedAdapter adapter) {
      final client = ApiClient(tokens: auth);
      client.dio.httpClientAdapter = adapter;

      return client;
    }

    String? bearer(RequestOptions options) => options.headers['Authorization'] as String?;

    test('carry the access token; public requests never do', () async {
      final adapter = _ScriptedAdapter((_) => 200);
      final client = clientWith(controller(_session(access: 'tok')), adapter);

      await client.dio.get<dynamic>('/api/venue/me');
      await client.dio.get<dynamic>('/api/restaurants');
      await client.dio.get<dynamic>('/api/faq');

      expect(bearer(adapter.seen[0]), 'Bearer tok');
      expect(bearer(adapter.seen[1]), isNull);
      expect(bearer(adapter.seen[2]), isNull);
    });

    test('a token about to expire is renewed before the request goes out', () async {
      repository.onRefresh = (_) => _session(access: 'fresh', refresh: 'refresh-2');
      final adapter = _ScriptedAdapter((_) => 200);
      final client = clientWith(controller(_session(expiresIn: const Duration(seconds: 10))), adapter);

      await client.dio.get<dynamic>('/api/venue/me');

      expect(bearer(adapter.seen.single), 'Bearer fresh');
    });

    test('a refused token is renewed and the request repeated once', () async {
      repository.onRefresh = (_) => _session(access: 'renewed', refresh: 'refresh-2');
      final adapter = _ScriptedAdapter((options) => bearer(options) == 'Bearer renewed' ? 200 : 401);
      final auth = controller(_session(access: 'revoked'));
      final client = clientWith(auth, adapter);

      final response = await client.dio.get<dynamic>('/api/venue/me');

      expect(response.statusCode, 200);
      expect(adapter.seen.map(bearer), ['Bearer revoked', 'Bearer renewed']);
      expect(repository.refreshCalls, hasLength(1));
      expect(auth.state?.accessToken, 'renewed');
    });

    test('if renewing is not possible the refusal reaches the caller and the person is signed out', () async {
      repository.onRefresh = (_) => null;
      final adapter = _ScriptedAdapter((_) => 401);
      final auth = controller(_session());
      final client = clientWith(auth, adapter);

      await expectLater(
        client.dio.get<dynamic>('/api/venue/me'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
      );
      expect(auth.state, isNull);
      expect(adapter.seen, hasLength(1), reason: 'nothing to repeat without a new token');
    });

    test('a request refused again after renewing is not repeated forever', () async {
      repository.onRefresh = (_) => _session(access: 'renewed', refresh: 'refresh-2');
      final adapter = _ScriptedAdapter((_) => 401);
      final client = clientWith(controller(_session()), adapter);

      await expectLater(client.dio.get<dynamic>('/api/venue/me'), throwsA(isA<DioException>()));
      expect(adapter.seen, hasLength(2), reason: 'the original and exactly one retry');
      expect(repository.refreshCalls, hasLength(1));
    });

    test('other errors are left alone, with no renewal', () async {
      final adapter = _ScriptedAdapter((_) => 403);
      final client = clientWith(controller(_session()), adapter);

      await expectLater(
        client.dio.get<dynamic>('/api/venue/staff'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 403)),
      );
      expect(repository.refreshCalls, isEmpty);
    });
  });
}
