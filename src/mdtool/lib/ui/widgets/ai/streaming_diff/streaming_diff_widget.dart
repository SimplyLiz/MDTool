import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'streaming_diff_controller.dart';
import 'streaming_diff_model.dart';

/// Renders the current StreamingDiff state. Caller wires the controller +
/// commit callback. On commit (last block decided), [onCommit] is called with
/// the final text and the widget can be dismissed.
class StreamingDiffWidget extends StatefulWidget {
  const StreamingDiffWidget({
    super.key,
    required this.controller,
    required this.onCommit,
    required this.onCancel,
  });

  final StreamingDiffController controller;
  final void Function(String committedText) onCommit;
  final VoidCallback onCancel;

  @override
  State<StreamingDiffWidget> createState() => _StreamingDiffWidgetState();
}

class _StreamingDiffWidgetState extends State<StreamingDiffWidget> {
  int _cursorBlock = 0;
  bool _committed = false;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    _focus.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    final s = widget.controller.state;
    if (s != null && s.isFullyStreamed && s.blocks.every((b) =>
        b.status == BlockStatus.accepted || b.status == BlockStatus.rejected)) {
      if (_committed) return;
      _committed = true;
      widget.onCommit(s.committedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.state;
    if (s == null) return const SizedBox.shrink();
    return KeyboardListener(
      focusNode: _focus,
      onKeyEvent: _handleKey,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (s.error != null) Text('Error: ${s.error}', style: const TextStyle(color: Colors.red)),
            for (var i = 0; i < s.blocks.length; i++) _blockRow(s.blocks[i], i == _cursorBlock),
            const SizedBox(height: 4),
            const Text('Tab: next  ·  Enter: accept current  ·  Backspace: reject current  ·  Esc: cancel',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  Widget _blockRow(StreamingBlock b, bool focused) {
    final pillColor = switch (b.status) {
      BlockStatus.accepted => Colors.green,
      BlockStatus.rejected => Colors.grey,
      BlockStatus.streamed => Colors.blue,
      BlockStatus.streaming => Colors.orange,
    };
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: focused ? Colors.deepPurple : Colors.transparent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.originalText, style: const TextStyle(
            color: Colors.red, decoration: TextDecoration.lineThrough)),
          Text(b.newText, style: const TextStyle(color: Colors.green)),
        ])),
        Column(children: [
          IconButton(icon: const Icon(Icons.check, size: 14), color: pillColor,
            onPressed: () => widget.controller.accept(b.idx)),
          IconButton(icon: const Icon(Icons.close, size: 14), color: pillColor,
            onPressed: () => widget.controller.reject(b.idx)),
        ])
      ]),
    );
  }

  void _handleKey(KeyEvent ev) {
    if (ev is! KeyDownEvent) return;
    final s = widget.controller.state;
    if (s == null) return;
    if (s.blocks.isEmpty) return;
    if (ev.logicalKey == LogicalKeyboardKey.tab) {
      setState(() => _cursorBlock = (_cursorBlock + 1) % s.blocks.length);
    } else if (ev.logicalKey == LogicalKeyboardKey.enter) {
      widget.controller.accept(_cursorBlock);
    } else if (ev.logicalKey == LogicalKeyboardKey.backspace) {
      widget.controller.reject(_cursorBlock);
    } else if (ev.logicalKey == LogicalKeyboardKey.escape) {
      widget.controller.cancel(); widget.onCancel();
    }
  }
}
