/// A signed-in owner or waiter: the short-lived access token the API checks on every request, and the
/// long-lived refresh token the app trades for a new access token so the person isn't asked for the
/// password again.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.roles,
  });

  /// Reads the API's sign-in / registration / refresh response.
  factory AuthSession.fromApi(Map<String, dynamic> json) => AuthSession(
        accessToken: json['token'] as String,
        accessExpiresAt: DateTime.parse(json['expiresAtUtc'] as String),
        refreshToken: json['refreshToken'] as String,
        roles: ((json['roles'] as List?) ?? const []).map((role) => '$role').toList(),
      );

  /// Reads what [toJson] wrote to the device.
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String,
        accessExpiresAt: DateTime.parse(json['accessExpiresAt'] as String),
        refreshToken: json['refreshToken'] as String,
        roles: ((json['roles'] as List?) ?? const []).map((role) => '$role').toList(),
      );

  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final List<String> roles;

  bool get isOwner => roles.contains('Owner');

  bool get isStaff => roles.contains('Staff');

  /// Whether the access token is already expired, or will be within [margin] (so it isn't sent just as it dies).
  bool accessExpiresWithin(Duration margin) => !accessExpiresAt.isAfter(DateTime.now().add(margin));

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'accessExpiresAt': accessExpiresAt.toUtc().toIso8601String(),
        'refreshToken': refreshToken,
        'roles': roles,
      };
}
