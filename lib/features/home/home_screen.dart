import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/inspection_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/remote/auth_repository.dart';
import '../inspection/inspection_screen.dart';
import '../scan/scan_screen.dart';
import 'sync_badge.dart';

/// Start screen: the list of saved inspections and a button to scan a new asset.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _scanAndStart(BuildContext context, WidgetRef ref) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (code == null) return;
    final inspection =
        await ref.read(inspectionRepositoryProvider).openOrStartDraft(code);
    if (context.mounted) _open(context, inspection);
  }

  void _open(BuildContext context, Inspection inspection) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InspectionScreen(inspection: inspection)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspections = ref.watch(inspectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FieldPilot'),
        actions: [
          const SyncBadge(),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: inspections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No inspections yet'))
            : ListView(
                children: [
                  for (final item in items)
                    ListTile(
                      leading: const Icon(Icons.assignment),
                      title: Text(item.assetCode),
                      subtitle: Text(item.status),
                      trailing: item.serverWonAt != null
                          ? Icon(
                              Icons.sync_problem,
                              color: Theme.of(context).colorScheme.error,
                              semanticLabel: 'Changed on the server',
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => _open(context, item),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scanAndStart(context, ref),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan asset'),
      ),
    );
  }
}
