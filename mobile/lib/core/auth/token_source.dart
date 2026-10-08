/// Hands out the access token for requests that need a signed-in person.
abstract interface class TokenSource {
  /// A token that is good to send right now (renewed first if it is about to expire), or `null` when
  /// nobody is signed in or the token couldn't be renewed.
  Future<String?> validAccessToken();

  /// Renews the session after the server refused the current token, returning the new token, or `null`
  /// if that wasn't possible.
  Future<String?> refreshAccessToken();
}
