import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/outbox_status.dart';

/// Cloud icon with the number of changes waiting to sync (hidden when 0).
class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingOpsProvider).value ?? 0;

    return Tooltip(
      message: pending == 0 ? 'Everything synced' : '$pending waiting to sync',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Badge.count(
          count: pending,
          isLabelVisible: pending > 0,
          child: Icon(pending == 0 ? Icons.cloud_done : Icons.cloud_upload),
        ),
      ),
    );
  }
}
