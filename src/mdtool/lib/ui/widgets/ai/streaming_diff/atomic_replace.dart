import 'package:flutter/material.dart';

/// Replaces a range in a TextEditingController atomically — Cmd+Z undoes the
/// whole replacement as a single history entry (since it's one `value =` set).
void atomicReplace({
  required TextEditingController controller,
  required int start,
  required int end,
  required String replacement,
}) {
  final text = controller.text;
  final before = text.substring(0, start);
  final after = text.substring(end);
  controller.value = TextEditingValue(
    text: '$before$replacement$after',
    selection: TextSelection.collapsed(offset: start + replacement.length),
    composing: TextRange.empty,
  );
}
