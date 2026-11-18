import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/outbox_status.dart';
import '../../sync/push_engine.dart';
import '../../sync/sync_scheduler.dart';

/// Cloud button with the number of changes waiting to sync (hidden when 0).
/// Syncing happens by itself; tapping the cloud just does it right now.
class SyncBadge extends ConsumerStatefulWidget {
  const SyncBadge({super.key});

  @override
  ConsumerState<SyncBadge> createState() => _SyncBadgeState();
}

class _SyncBadgeState extends ConsumerState<SyncBadge> {
  late final AppLifecycleListener _lifecycle;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    // Back in the app (maybe with internet again): try at once.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(syncSchedulerProvider).syncNow(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final result = await ref.read(syncSchedulerProvider).syncNow();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(syncMessage(result))));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncSchedulerProvider); // keeps automatic sync running
    final pending = ref.watch(pendingOpsProvider).value ?? 0;

    if (_syncing) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox.square(dimension: 24, child: CircularProgressIndicator()),
      );
    }
    return IconButton(
      tooltip: pending == 0 ? 'Everything synced' : '$pending waiting to sync',
      onPressed: _sync,
      icon: Badge.count(
        count: pending,
        isLabelVisible: pending > 0,
        child: Icon(pending == 0 ? Icons.cloud_done : Icons.cloud_upload),
      ),
    );
  }
}

/// Short text for the user about one sync run.
String syncMessage(PushResult result) {
  if (result.failed) {
    return 'No connection. Your changes are safe and will be sent later.';
  }
  final parts = ['Synced ${result.sent} change(s).'];
  if (result.conflicts > 0) {
    parts.add('${result.conflicts} were changed on the server; the server version was kept.');
  }
  if (result.rejected > 0) {
    parts.add('${result.rejected} were refused by the server and removed.');
  }
  return parts.join(' ');
}
