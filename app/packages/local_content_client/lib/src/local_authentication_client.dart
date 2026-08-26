import 'dart:async';

import 'package:authentication_client/authentication_client.dart';

/// Signs the app in as a single fixed reader, with no backend.
///
/// The product has no accounts. There is one case a day, the same one for
/// everybody, and nothing a reader does is stored anywhere. Rather than bolt an
/// auth screen onto that, this satisfies the existing [AuthenticationClient]
/// seam with a user who is always present, so every screen that asks "who is
/// signed in" gets a real answer and the login flow never appears.
///
/// Every mutating method throws rather than silently doing nothing: if a screen
/// we thought was unreachable calls one, the failure should be loud and in a
/// stack trace, not a button that quietly does not work.
class LocalAuthenticationClient implements AuthenticationClient {
  LocalAuthenticationClient();

  /// The reader. Not a person — a seat.
  static const reader = AuthenticationUser(
    id: 'gi-daily-reader',
    email: 'leser@gi-daily.example',
    username: 'Leser',
    fullName: 'Leser',
    isNewUser: false,
  );

  @override
  Stream<AuthenticationUser> get user => Stream.value(reader);

  @override
  Future<void> logInWithPassword({
    required String password,
    String? email,
    String? phone,
  }) async =>
      throw UnsupportedError('this build has no accounts');

  @override
  Future<void> logInWithGoogle() async =>
      throw UnsupportedError('this build has no accounts');

  @override
  Future<void> logInWithGithub() async =>
      throw UnsupportedError('this build has no accounts');

  @override
  Future<void> signUpWithPassword({
    required String password,
    required String fullName,
    required String username,
    String? avatarUrl,
    String? email,
    String? phone,
    String? pushToken,
  }) async =>
      throw UnsupportedError('this build has no accounts');

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async =>
      throw UnsupportedError('this build has no accounts');

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String newPassword,
  }) async =>
      throw UnsupportedError('this build has no accounts');

  @override
  Future<void> logOut() async {
    // Nothing to sign out of. Returning quietly keeps any stray menu item from
    // crashing the app during a demo.
  }
}
