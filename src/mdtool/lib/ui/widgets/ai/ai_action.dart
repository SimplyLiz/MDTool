import 'package:mdtool/core/services/ai/worker/ai_worker_types.dart';

/// User-initiated intent for an AI operation. Wider than RefineOp because future
/// phases will add Refine+Knowledge, Tone, Compare, etc.
enum AIAction { refine, shorten, translate }

extension AIActionMapping on AIAction {
  RefineOp get asRefineOp => switch (this) {
    AIAction.refine => RefineOp.refine,
    AIAction.shorten => RefineOp.shorten,
    AIAction.translate => RefineOp.translate,
  };
  String get label => switch (this) {
    AIAction.refine => 'Refine',
    AIAction.shorten => 'Shorten',
    AIAction.translate => 'Translate',
  };
  String get tooltip => switch (this) {
    AIAction.refine => 'Improve clarity, grammar, and readability',
    AIAction.shorten => 'Reduce length, preserve key meaning',
    AIAction.translate => 'Translate between German and English',
  };
}

class AIIntent {
  final AIAction action;
  final String selectedText;
  /// Bytes offset in the underlying doc where selection starts.
  final int selectionStart;
  final int selectionEnd;
  /// True if user held Alt while invoking (reserved for Phase 3 compare-mode).
  final bool altModifier;
  const AIIntent({
    required this.action,
    required this.selectedText,
    required this.selectionStart,
    required this.selectionEnd,
    this.altModifier = false,
  });
}
