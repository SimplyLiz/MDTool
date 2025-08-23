import 'package:flutter/material.dart';

enum SaveChangesAction {
  save,
  discard,
  cancel,
}

class SaveChangesDialog extends StatelessWidget {
  final String? fileName;
  final bool isUntitled;

  const SaveChangesDialog({
    super.key,
    this.fileName,
    this.isUntitled = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = isUntitled 
        ? 'Untitled Document'
        : fileName?.split('/').last ?? 'Document';

    return AlertDialog(
      title: const Text('Save Changes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The document "$displayName" has unsaved changes.'),
          const SizedBox(height: 8),
          const Text('Do you want to save your changes before closing?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(SaveChangesAction.discard),
          child: const Text('Discard Changes'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(SaveChangesAction.cancel),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(SaveChangesAction.save),
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Shows the save changes dialog and returns the user's choice
  static Future<SaveChangesAction?> show(
    BuildContext context, {
    String? fileName,
    bool isUntitled = false,
  }) async {
    return await showDialog<SaveChangesAction>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => SaveChangesDialog(
        fileName: fileName,
        isUntitled: isUntitled,
      ),
    );
  }
}