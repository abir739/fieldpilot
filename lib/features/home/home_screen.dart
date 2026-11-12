import 'package:flutter/material.dart';

import '../scan/scan_screen.dart';

/// Start screen: scan an asset to begin an inspection.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastCode; // shown for now; next step starts an inspection with it

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (code != null) setState(() => _lastCode = code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FieldPilot')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_lastCode != null) Text('Asset: $_lastCode'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan asset'),
            ),
          ],
        ),
      ),
    );
  }
}
