import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/auth_repository.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Shows the login screen until someone is signed in, then the app.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);

    return signedIn.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (yes) => yes ? const HomeScreen() : const LoginScreen(),
    );
  }
}
