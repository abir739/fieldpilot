import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/sync/push_engine.dart';
import 'package:fieldpilot/sync/sync_scheduler.dart';

/// A fake push that counts its runs and fails while [offline] is true.
class FakePush {
  int runs = 0;
  bool offline = false;
  Completer<void>? hold; // when set, a run waits until it is completed

  Future<PushResult> call() async {
    runs++;
    await hold?.future;
    return PushResult(failed: offline);
  }
}

void main() {
  test('backoff doubles and stops at 5 minutes', () {
    expect(retryDelay(1), const Duration(seconds: 5));
    expect(retryDelay(2), const Duration(seconds: 10));
    expect(retryDelay(3), const Duration(seconds: 20));
    expect(retryDelay(20), const Duration(minutes: 5));
  });

  test('many edits in a row become one push', () {
    fakeAsync((time) {
      final push = FakePush();
      final scheduler = SyncScheduler(push.call);

      scheduler.poke();
      time.elapse(const Duration(seconds: 1));
      scheduler.poke(); // typing again restarts the pause
      time.elapse(const Duration(seconds: 1));
      expect(push.runs, 0);

      time.elapse(const Duration(seconds: 1));
      expect(push.runs, 1);
    });
  });

  test('offline: retries later with longer waits, then succeeds', () {
    fakeAsync((time) {
      final push = FakePush()..offline = true;
      final scheduler = SyncScheduler(push.call);

      scheduler.syncNow(); // fails -> retry in 5s
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 5));
      expect(push.runs, 2); // fails -> retry in 10s

      scheduler.poke(); // an edit while offline does not cut the wait
      time.elapse(const Duration(seconds: 9));
      expect(push.runs, 2);

      push.offline = false;
      time.elapse(const Duration(seconds: 1));
      expect(push.runs, 3); // back online: sent

      time.elapse(const Duration(minutes: 10));
      expect(push.runs, 3); // and no more retries
    });
  });

  test('only one push at a time; a request during it runs right after', () {
    fakeAsync((time) {
      final push = FakePush()..hold = Completer<void>();
      final scheduler = SyncScheduler(push.call);

      scheduler.syncNow();
      scheduler.syncNow(); // while the first one is still running
      time.flushMicrotasks();
      expect(push.runs, 1);

      push.hold!.complete();
      push.hold = null;
      time.elapse(const Duration(seconds: 2));
      expect(push.runs, 2); // the second request was not lost
    });
  });
}
