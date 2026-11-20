import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'outbox_status.dart';
import 'pull_engine.dart';
import 'push_engine.dart';

/// Wait before retrying after [failures] failed runs in a row:
/// 5s, 10s, 20s, 40s ... never more than 5 minutes.
Duration retryDelay(int failures) =>
    Duration(seconds: min(5 * pow(2, failures - 1).toInt(), 300));

/// Decides WHEN to push, so the user never has to tap anything.
///
/// - [poke]: a new edit. Push soon, after a short pause so a burst of
///   typing becomes one sync.
/// - [syncNow]: push right away (the user tapped the cloud, or the app
///   came back to the screen).
/// - After a failed run, try again later, waiting longer each time (backoff).
/// - Only one push runs at a time. A request during a run is not lost:
///   one more run follows.
class SyncScheduler {
  SyncScheduler(this._push, {this.pause = const Duration(seconds: 2)});

  final Future<PushResult> Function() _push;
  final Duration pause;

  Timer? _timer;
  Future<PushResult>? _running;
  bool _again = false;
  int _failures = 0;

  void poke() {
    // While failing, a retry is already planned: keep its longer wait, so
    // typing offline does not hammer the network every 2 seconds.
    if (_failures == 0) _startTimer(pause);
  }

  Future<PushResult> syncNow() {
    _timer?.cancel();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _run();
  }

  Future<PushResult> _run() async {
    try {
      final result = await _push();
      if (result.failed) {
        _failures++;
        _startTimer(retryDelay(_failures));
      } else {
        _failures = 0;
      }
      return result;
    } finally {
      _running = null;
      if (_again) {
        _again = false;
        poke();
      }
    }
  }

  void _startTimer(Duration wait) {
    _timer?.cancel();
    _timer = Timer(wait, syncNow);
  }

  void dispose() => _timer?.cancel();
}

/// One full sync: send our changes first, then get the server's.
/// Push first, so a pull never brings back an old copy of something we edited.
Future<PushResult> pushThenPull(PushEngine push, PullEngine pull) async {
  final pushed = await push.pushAll();
  if (pushed.failed) return pushed;
  try {
    await pull.pullAll();
    return pushed;
  } catch (_) {
    return PushResult(
      sent: pushed.sent,
      conflicts: pushed.conflicts,
      rejected: pushed.rejected,
      failed: true,
    );
  }
}

/// The app's scheduler. It syncs when the app opens and whenever changes
/// wait in the outbox.
final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final push = ref.watch(pushEngineProvider);
  final pull = ref.watch(pullEngineProvider);
  final scheduler = SyncScheduler(() => pushThenPull(push, pull));
  ref.listen(pendingOpsProvider, (_, pending) {
    if ((pending.value ?? 0) > 0) scheduler.poke();
  });
  scheduler.poke(); // app opened: get what changed on the server
  ref.onDispose(scheduler.dispose);
  return scheduler;
});
