import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_action.dart';

class SelectionToolbar extends StatelessWidget {
  const SelectionToolbar({
    super.key,
    required this.selectedText,
    required this.selectionStart,
    required this.selectionEnd,
    required this.onAction,
  });

  final String selectedText;
  final int selectionStart;
  final int selectionEnd;
  final void Function(AIIntent intent) onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in AIAction.values) _button(context, a),
          ],
        ),
      ),
    );
  }

  Widget _button(BuildContext context, AIAction a) {
    return Tooltip(
      message: a.tooltip,
      child: TextButton(
        onPressed: () {
          final alt = HardwareKeyboard.instance.isAltPressed;
          onAction(AIIntent(
            action: a,
            selectedText: selectedText,
            selectionStart: selectionStart,
            selectionEnd: selectionEnd,
            altModifier: alt,
          ));
        },
        child: Text(a.label),
      ),
    );
  }
}
