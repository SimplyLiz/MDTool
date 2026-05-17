import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_action.dart';

/// Returns `PopupMenuEntry`s representing the AI section. Use as
/// `buildAiContextMenu(...).forEach(items.add)` inside the existing
/// context-menu builder.
List<PopupMenuEntry<AIIntent>> buildAiContextMenu({
  required String selectedText,
  required int selectionStart,
  required int selectionEnd,
}) {
  if (selectedText.isEmpty) return const [];
  return [
    const PopupMenuDivider(),
    const PopupMenuItem(enabled: false, child: Text('AI', style: TextStyle(fontSize: 11, color: Colors.grey))),
    for (final a in AIAction.values)
      PopupMenuItem<AIIntent>(
        value: AIIntent(
          action: a,
          selectedText: selectedText,
          selectionStart: selectionStart,
          selectionEnd: selectionEnd,
          altModifier: HardwareKeyboard.instance.isAltPressed,
        ),
        child: Row(children: [
          const SizedBox(width: 4),
          Text(a.label),
          const Spacer(),
          Text(a.tooltip, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
  ];
}
