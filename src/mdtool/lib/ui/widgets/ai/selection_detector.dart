import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'ai_action.dart';
import 'selection_toolbar.dart';

/// Wraps a child editor widget; when [controller] reports a non-empty selection,
/// it overlays a [SelectionToolbar] positioned above the selection.
class SelectionDetector extends StatefulWidget {
  const SelectionDetector({
    super.key,
    required this.controller,
    required this.child,
    required this.onAction,
  });

  final TextEditingController controller;
  final Widget child;
  final void Function(AIIntent intent) onAction;

  @override
  State<SelectionDetector> createState() => _SelectionDetectorState();
}

class _SelectionDetectorState extends State<SelectionDetector> {
  TextSelection? _lastSel;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSelChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSelChange);
    _entry?.remove();
    super.dispose();
  }

  void _onSelChange() {
    final sel = widget.controller.selection;
    if (sel == _lastSel) return;
    _lastSel = sel;
    if (!sel.isValid || sel.isCollapsed) {
      _hide();
      return;
    }
    _show(sel);
  }

  void _show(TextSelection sel) {
    _entry?.remove();
    final selectedText = widget.controller.text.substring(sel.start, sel.end);
    _entry = OverlayEntry(builder: (ctx) {
      // Simplified positioning: anchor near the top-right of the editor area.
      // Accurate caret-relative positioning will come in a later phase once we
      // hook into the underlying CodeMirror/flutter_code_editor coords API.
      return Positioned(
        top: 8,
        right: 8,
        child: SelectionToolbar(
          selectedText: selectedText,
          selectionStart: sel.start,
          selectionEnd: sel.end,
          onAction: (intent) {
            widget.onAction(intent);
            _hide();
          },
        ),
      );
    });
    Overlay.of(context).insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
