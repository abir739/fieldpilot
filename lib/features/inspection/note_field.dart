import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/inspection_repository.dart';

/// Free-text note. Saved on the phone as the user types.
class NoteField extends ConsumerStatefulWidget {
  const NoteField({
    super.key,
    required this.inspectionId,
    required this.initialNote,
  });

  final String inspectionId;
  final String initialNote;

  @override
  ConsumerState<NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends ConsumerState<NoteField> {
  // Filled once from the saved note; after that the text field owns the text,
  // so the cursor never jumps while typing.
  late final _controller = TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 6,
        decoration: const InputDecoration(
          labelText: 'Note',
          hintText: 'What did you see? e.g. small oil leak under the pump',
          border: OutlineInputBorder(),
        ),
        onChanged: (text) => ref
            .read(inspectionRepositoryProvider)
            .setNote(widget.inspectionId, text),
      ),
    );
  }
}
