import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_service.dart';

/// Push notifications through Firebase Cloud Messaging. Only Android is set up (its `google-services.json` is in
/// the project); anywhere else, or if Firebase can't start, [start] gives back [NoPushService] and the app
/// carries on, since the screens also refresh themselves while the app is open.
class FirebasePushService implements PushService {
  FirebasePushService._(this._messaging) {
    FirebaseMessaging.onMessage.listen((message) => _add(_arrivals, message));
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _add(_taps, message));
  }

  final FirebaseMessaging _messaging;
  final _arrivals = StreamController<PushEvent>.broadcast();
  final _taps = StreamController<PushEvent>.broadcast();

  static Future<PushService> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return const NoPushService();

    try {
      await Firebase.initializeApp();
      final service = FirebasePushService._(FirebaseMessaging.instance);

      // The notification that launched the app is delivered once the app is ready to react to it.
      final launch = await FirebaseMessaging.instance.getInitialMessage();
      if (launch != null) {
        Timer(const Duration(milliseconds: 500), () => _add(service._taps, launch));
      }

      return service;
    } catch (error) {
      debugPrint('Push notifications are off: $error');

      return const NoPushService();
    }
  }

  static void _add(StreamController<PushEvent> sink, RemoteMessage message) {
    final type = message.data['type'];
    final code = message.data['code'];
    if (type is String && code is String) sink.add(PushEvent(type: type, code: code));
  }

  @override
  Future<String?> token() async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return null;

      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<PushEvent> get arrivals => _arrivals.stream;

  @override
  Stream<PushEvent> get taps => _taps.stream;
}
