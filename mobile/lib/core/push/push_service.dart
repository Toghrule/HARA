import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a push notification is about, read from the data the server attaches to it.
class PushEvent {
  const PushEvent({required this.type, required this.code});

  /// `newRequest` (restaurant side), or `accepted` / `declined` (customer side).
  final String type;

  /// The reservation code the notification is about.
  final String code;

  bool get isNewRequest => type == 'newRequest';
}

/// The phone's push-notification connection. The real one talks to Firebase (see [FirebasePushService]);
/// everything else, including all tests, uses [NoPushService].
abstract class PushService {
  /// This phone's notification token, asking the person for permission first. `null` when there is none:
  /// permission refused, Firebase unavailable, or a platform without push.
  Future<String?> token();

  /// Fired when Firebase hands the phone a new token, which then has to be told to the server again.
  Stream<String> get tokenRefreshes;

  /// A notification arrived while the app is open.
  Stream<PushEvent> get arrivals;

  /// The person tapped a notification (from the lock screen, or the one that launched the app).
  Stream<PushEvent> get taps;
}

class NoPushService implements PushService {
  const NoPushService();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<PushEvent> get arrivals => const Stream.empty();

  @override
  Stream<PushEvent> get taps => const Stream.empty();
}

final pushServiceProvider = Provider<PushService>((ref) => const NoPushService());
