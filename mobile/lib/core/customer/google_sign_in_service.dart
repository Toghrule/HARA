import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Signing in with a Google account on this phone. Kept behind an interface so the rest of the app (and its tests) never touch Google.
abstract interface class GoogleSignInService {
  /// Whether Google sign-in can be offered on this phone at all.
  bool get isAvailable;

  /// Asks the person to pick their Google account. Gives back the Firebase token HARA's server checks, or `null` if they closed the window.
  /// Throws if something went wrong (no network, Google trouble).
  Future<String?> signIn();

  /// Forgets the Google account on this phone.
  Future<void> signOut();
}

/// The web client of the Firebase project (from `google-services.json`, the entry of type 3). Google needs it to hand out a token the
/// server can check. It is not a secret.
const _webClientId = '464617544539-j5nh8avmmps7n8tbhn91a0dccq9sk22l.apps.googleusercontent.com';

/// Google sign-in through Firebase on Android (the only platform set up).
class FirebaseGoogleSignInService implements GoogleSignInService {
  FirebaseGoogleSignInService();

  bool _ready = false;

  @override
  bool get isAvailable => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _prepare() async {
    if (_ready) return;

    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    _ready = true;
  }

  @override
  Future<String?> signIn() async {
    await _prepare();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      // Closing the window is not a failure.
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final googleToken = account.authentication.idToken;
    if (googleToken == null) throw StateError('Google gave no token.');

    // Firebase turns the Google token into its own, which is what HARA's server checks.
    final credential = GoogleAuthProvider.credential(idToken: googleToken);
    final signedIn = await FirebaseAuth.instance.signInWithCredential(credential);

    return signedIn.user?.getIdToken();
  }

  @override
  Future<void> signOut() async {
    try {
      await _prepare();
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Signing out here must never keep anyone signed in.
    }
  }
}

/// Nothing offered: web, iOS or a test.
class NoGoogleSignInService implements GoogleSignInService {
  const NoGoogleSignInService();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> signIn() async => null;

  @override
  Future<void> signOut() async {}
}

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) => FirebaseGoogleSignInService());
