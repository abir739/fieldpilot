import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/auth_repository.dart';

/// Email + password login, with a button to create an account.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Runs sign in or sign up. On success AuthGate switches to the app by itself.
  Future<void> _run(Future<void> Function(String, String) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(_email.text.trim(), _password.text);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No connection. Login needs internet the first time.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUp(String email, String password) async {
    final signedIn = await ref.read(authRepositoryProvider).signUp(email, password);
    if (!signedIn) {
      // Not an error, but the user must act: tell them clearly.
      setState(() => _error = 'Account created. Open the link in your email, then sign in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthRepository auth() => ref.read(authRepositoryProvider); // only on tap

    return Scaffold(
      appBar: AppBar(title: const Text('FieldPilot')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password (min 6)'),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : () => _run(auth().signIn),
            child: const Text('Sign in'),
          ),
          TextButton(
            onPressed: _busy ? null : () => _run(_signUp),
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }
}
