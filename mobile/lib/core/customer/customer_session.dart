import '../auth/auth_session.dart';

/// A customer who signed in with Google: HARA's own tokens (not Google's) and what the app shows about them.
class CustomerSession {
  const CustomerSession({required this.auth, this.name, this.photoUrl});

  /// Reads the server's answer to a Google sign-in.
  factory CustomerSession.fromApi(Map<String, dynamic> json) => CustomerSession(
        auth: AuthSession.fromApi(json),
        name: json['name'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );

  /// Reads what [toJson] wrote to the device.
  factory CustomerSession.fromJson(Map<String, dynamic> json) => CustomerSession(
        auth: AuthSession.fromJson(json['auth'] as Map<String, dynamic>),
        name: json['name'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );

  final AuthSession auth;

  /// First name and the initial of the last ("Anna K."), as other people see it next to a review.
  final String? name;
  final String? photoUrl;

  CustomerSession withAuth(AuthSession next) => CustomerSession(auth: next, name: name, photoUrl: photoUrl);

  Map<String, dynamic> toJson() => {'auth': auth.toJson(), 'name': name, 'photoUrl': photoUrl};
}
