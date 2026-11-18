import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fieldpilot/data/remote/auth_repository.dart';

void main() {
  test('offline token refresh error keeps the user signed in', () async {
    final events = StreamController<AuthState>();
    final values = <bool>[];
    final errors = <Object>[];
    signedInStream(events.stream, initiallySignedIn: true)
        .listen(values.add, onError: errors.add);

    // What Supabase sends in airplane mode when the token expires.
    events.addError(AuthRetryableFetchException(message: 'Failed host lookup'));
    await events.close();
    await pumpEventQueue();

    expect(values, [true]); // still signed in
    expect(errors, isEmpty); // the error did not reach the app
  });

  test('signing out is still reported', () async {
    final events = StreamController<AuthState>();
    final values = <bool>[];
    signedInStream(events.stream, initiallySignedIn: true).listen(values.add);

    events.add(const AuthState(AuthChangeEvent.signedOut, null));
    await events.close();
    await pumpEventQueue();

    expect(values, [true, false]);
  });
}
