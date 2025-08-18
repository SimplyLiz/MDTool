import 'th_intra_line_diff.dart';

/// Represents a single line in a diff with its type and content.
/// 
/// This class encapsulates all information about a single line within
/// a diff operation, including its content, type (addition/deletion/context),
/// and position information in both the original and modified texts.
/// 
/// Each line in a diff is classified as one of three types:
/// - **Context**: Unchanged lines that provide context around changes
/// - **Addition**: Lines that were added in the modified text
/// - **Deletion**: Lines that were removed from the original text
/// 
/// Line numbers are tracked separately for original and modified texts:
/// - Added lines have no original line number (null)
/// - Deleted lines have no modified line number (null)
/// - Context lines have both line numbers
/// 
/// For enhanced diff visualization, lines can optionally include intra-line
/// diff information that highlights specific character or word changes within
/// the line content.
/// 
/// Example usage:
/// ```dart
/// final line = THDiffLine(
///   type: THDiffLineType.addition,
///   content: 'new line of code',
///   oldLineNumber: null,
///   newLineNumber: 42,
/// );
/// 
/// print('${line.type.prefix}${line.content}'); // "+new line of code"
/// ```
class THDiffLine {
  /// The type of change for this line.
  /// 
  /// Indicates whether this line represents an addition, deletion,
  /// or unchanged context. This determines how the line is displayed
  /// in diff output formats.
  final THDiffLineType type;
  
  /// The actual content of the line.
  /// 
  /// Contains the text content of the line without any diff prefixes
  /// or formatting. This is the raw line content as it appears in
  /// the source text.
  final String content;
  
  /// Line number in the original file (null if line was added).
  /// 
  /// For context and deletion lines, this indicates the line number
  /// in the original text. For addition lines, this is null since
  /// the line doesn't exist in the original.
  /// 
  /// Line numbers are 1-based following standard conventions.
  final int? oldLineNumber;
  
  /// Line number in the modified file (null if line was deleted).
  /// 
  /// For context and addition lines, this indicates the line number
  /// in the modified text. For deletion lines, this is null since
  /// the line doesn't exist in the modified text.
  /// 
  /// Line numbers are 1-based following standard conventions.
  final int? newLineNumber;
  
  /// Detailed intra-line differences for enhanced visualization.
  /// 
  /// When present, this provides character or word-level change information
  /// within the line content. This enables highlighting specific parts of
  /// the line that changed rather than marking the entire line.
  /// 
  /// This is primarily useful for modified lines where the old and new
  /// versions are similar but not identical.
  final List<THIntraLineDiff>? intraLineDiffs;
  
  const THDiffLine({
    required this.type,
    required this.content,
    this.oldLineNumber,
    this.newLineNumber,
    this.intraLineDiffs,
  });
  
  /// Creates a copy of this line with some fields changed.
  /// 
  /// This method provides an immutable way to create a new THDiffLine
  /// instance with modified fields while preserving all other data.
  /// 
  /// Parameters (all optional):
  /// - [type]: New line type
  /// - [content]: New line content
  /// - [oldLineNumber]: New original line number
  /// - [newLineNumber]: New modified line number
  /// - [intraLineDiffs]: New intra-line diff information
  /// 
  /// Returns a new [THDiffLine] instance with the specified fields updated.
  THDiffLine copyWith({
    THDiffLineType? type,
    String? content,
    int? oldLineNumber,
    int? newLineNumber,
    List<THIntraLineDiff>? intraLineDiffs,
  }) {
    return THDiffLine(
      type: type ?? this.type,
      content: content ?? this.content,
      oldLineNumber: oldLineNumber ?? this.oldLineNumber,
      newLineNumber: newLineNumber ?? this.newLineNumber,
      intraLineDiffs: intraLineDiffs ?? this.intraLineDiffs,
    );
  }
  
  /// Whether this line represents a change (addition or deletion).
  /// 
  /// Returns `true` if the line is either an addition or deletion,
  /// `false` if it's a context line. This is useful for filtering
  /// or counting only the lines that represent actual changes.
  bool get isChange => type == THDiffLineType.addition || type == THDiffLineType.deletion;
  
  /// Whether this line is unchanged context.
  /// 
  /// Returns `true` if the line represents unchanged content that
  /// provides context around changes, `false` if it's an addition
  /// or deletion. Context lines appear in both original and modified texts.
  bool get isContext => type == THDiffLineType.context;
  
  /// Whether this line has intra-line diff information
  /// 
  /// Returns `true` if this line contains character or word-level diff
  /// information that can be used for enhanced visualization.
  bool get hasIntraLineDiff => intraLineDiffs != null && intraLineDiffs!.isNotEmpty;
  
  /// Get all changed segments within this line
  /// 
  /// Returns only the intra-line diffs that represent actual changes
  /// (insertions or deletions), excluding equal segments.
  List<THIntraLineDiff> get intraLineChanges {
    if (!hasIntraLineDiff) return [];
    return intraLineDiffs!.where((diff) => diff.isChange).toList();
  }
  
  @override
  String toString() {
    final intraInfo = hasIntraLineDiff ? ', intraDiffs: ${intraLineDiffs!.length}' : '';
    return 'THDiffLine(type: $type, content: "$content", oldLine: $oldLineNumber, newLine: $newLineNumber$intraInfo)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is THDiffLine &&
        other.type == type &&
        other.content == content &&
        other.oldLineNumber == oldLineNumber &&
        other.newLineNumber == newLineNumber &&
        _listsEqual(other.intraLineDiffs, intraLineDiffs);
  }
  
  @override
  int get hashCode {
    return Object.hash(
      type, 
      content, 
      oldLineNumber, 
      newLineNumber,
      intraLineDiffs == null ? null : Object.hashAll(intraLineDiffs!),
    );
  }
  
  /// Helper method to compare lists of intra-line diffs
  static bool _listsEqual(List<THIntraLineDiff>? a, List<THIntraLineDiff>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Enum representing the type of change for a diff line.
/// 
/// This enum classifies each line in a diff according to how it changed
/// between the original and modified texts. The three types correspond
/// to the standard diff line classifications used in unified diff format.
/// 
/// The types are:
/// - [context]: Lines that are identical in both texts
/// - [addition]: Lines that were added in the modified text
/// - [deletion]: Lines that were removed from the original text
enum THDiffLineType {
  /// Line exists in both files (context).
  /// 
  /// These lines are unchanged between the original and modified texts.
  /// They provide context around changes and help locate where changes
  /// occurred. In diff output, these lines typically appear with a
  /// space prefix or no prefix.
  context,
  
  /// Line was added in the new file.
  /// 
  /// These lines exist in the modified text but not in the original text.
  /// They represent new content that was inserted. In diff output,
  /// these lines appear with a '+' prefix and are often highlighted
  /// in green.
  addition,
  
  /// Line was deleted from the original file.
  /// 
  /// These lines exist in the original text but not in the modified text.
  /// They represent content that was removed. In diff output, these
  /// lines appear with a '-' prefix and are often highlighted in red.
  deletion,
}

/// Extension to provide convenient methods for THDiffLineType.
/// 
/// This extension adds utility methods to the THDiffLineType enum
/// for formatting and display purposes. It provides standard
/// representations used in diff output formats.
extension THDiffLineTypeExtension on THDiffLineType {
  /// Gets the prefix character used in unified diff format.
  /// 
  /// Returns the single character that appears at the beginning
  /// of each line in unified diff output to indicate the line type:
  /// - Space (' ') for context lines
  /// - Plus ('+') for addition lines  
  /// - Minus ('-') for deletion lines
  /// 
  /// This follows the standard unified diff format conventions.
  String get prefix {
    switch (this) {
      case THDiffLineType.context:
        return ' ';
      case THDiffLineType.addition:
        return '+';
      case THDiffLineType.deletion:
        return '-';
    }
  }
  
  /// Gets a human-readable name for the line type.
  /// 
  /// Returns a descriptive string that can be used in user interfaces
  /// or documentation to explain what the line type represents:
  /// - "Context" for unchanged lines
  /// - "Addition" for added lines
  /// - "Deletion" for deleted lines
  String get displayName {
    switch (this) {
      case THDiffLineType.context:
        return 'Context';
      case THDiffLineType.addition:
        return 'Addition';
      case THDiffLineType.deletion:
        return 'Deletion';
    }
  }
}