import 'package:flutter/material.dart';

/// Tells the user the server's version replaced their edit (server wins).
/// Stays until they close it.
class ConflictBanner extends StatelessWidget {
  const ConflictBanner({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: colors.errorContainer,
      leading: Icon(Icons.sync_problem, color: colors.onErrorContainer),
      content: Text(
        'This inspection was changed on the server at the same time. '
        'The server version was kept, so your last edit was replaced.',
        style: TextStyle(color: colors.onErrorContainer),
      ),
      actions: [TextButton(onPressed: onDismiss, child: const Text('Got it'))],
    );
  }
}
