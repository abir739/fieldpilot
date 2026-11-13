import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/asset_code.dart';
import 'zoom_slider.dart';

/// Shows the live camera. The camera stays on; the last valid code it saw is
/// shown at the bottom, and the user taps "Use this code" to confirm it.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _camera = MobileScannerController();
  String? _found; // last valid code seen; null until one is seen

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final code = parseAssetCode(barcode.rawValue);
      if (code != null && code != _found) {
        setState(() => _found = code); // camera keeps running
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan asset QR')),
      body: Stack(
        children: [
          MobileScanner(controller: _camera, onDetect: _onDetect),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ZoomSlider(camera: _camera),
          ),
        ],
      ),
      bottomNavigationBar: _found == null
          ? null
          : _ConfirmBar(
              code: _found!,
              onUse: () => Navigator.of(context).pop(_found),
              onClear: () => setState(() => _found = null),
            ),
    );
  }
}

/// Shows the scanned code with "Clear" and "Use this code" buttons.
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.code,
    required this.onUse,
    required this.onClear,
  });

  final String code;
  final VoidCallback onUse;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(code, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onUse,
                    child: const Text('Use this code'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
