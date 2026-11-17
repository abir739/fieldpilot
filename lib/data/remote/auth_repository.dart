import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sign in, sign up and sign out with email + password (Supabase Auth).
/// The session is saved on the phone, so after one login the app works offline.
class AuthRepository {
  AuthRepository(this._auth);

  final GoTrueClient _auth;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  /// Creates an account. Returns false when Supabase is waiting for the user
  /// to click the link in a confirmation email (no session yet).
  Future<bool> signUp(String email, String password) async {
    final response = await _auth.signUp(email: email, password: password);
    return response.session != null;
  }

  Future<void> signOut() => _auth.signOut();

  /// true when someone is signed in. Emits again on every login / logout.
  Stream<bool> watchSignedIn() =>
      _auth.onAuthStateChange.map((state) => state.session != null);
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(Supabase.instance.client.auth),
);

final isSignedInProvider = StreamProvider<bool>(
  (ref) => ref.watch(authRepositoryProvider).watchSignedIn(),
);
