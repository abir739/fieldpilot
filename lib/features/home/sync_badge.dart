import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/outbox_status.dart';
import '../../sync/push_engine.dart';

/// Cloud button with the number of changes waiting to sync (hidden when 0).
/// Tap it to send them now.
class SyncBadge extends ConsumerStatefulWidget {
  const SyncBadge({super.key});

  @override
  ConsumerState<SyncBadge> createState() => _SyncBadgeState();
}

class _SyncBadgeState extends ConsumerState<SyncBadge> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final result = await ref.read(pushEngineProvider).pushAll();
    if (!mounted) return;
    setState(() => _syncing = false);

    final message = result.failed
        ? 'No connection. Your changes are safe and will be sent later.'
        : result.conflicts > 0
            ? 'Synced. ${result.conflicts} item(s) were changed on the server; the server version was kept.'
            : 'Synced ${result.sent} change(s).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
