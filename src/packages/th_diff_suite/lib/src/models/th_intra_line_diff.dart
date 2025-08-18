/// Models for representing character and word-level differences within lines
/// 
/// These classes provide fine-grained diff information that can be used to
/// highlight specific parts of lines that changed, rather than marking entire
/// lines as additions or deletions.

/// Represents a segment of text within a line with its change type
/// 
/// Used to highlight specific parts of lines that were added, deleted, or unchanged.
/// This enables more precise diff visualization with partial line highlighting.
class THIntraLineDiff {
  /// The type of change for this text segment
  final THIntraLineDiffType type;
  
  /// The text content of this segment
  final String text;
  
  /// Starting character position within the line
  final int startIndex;
  
  /// Ending character position within the line (exclusive)
  final int endIndex;
  
  const THIntraLineDiff({
    required this.type,
    required this.text,
    required this.startIndex,
    required this.endIndex,
  });
  
  /// Length of this text segment
  int get length => endIndex - startIndex;
  
  /// Whether this segment represents a change (addition or deletion)
  bool get isChange => type != THIntraLineDiffType.equal;
  
  /// Whether this segment is unchanged
  bool get isEqual => type == THIntraLineDiffType.equal;
  
  @override
  String toString() {
    return 'THIntraLineDiff(type: $type, text: "$text", range: $startIndex-$endIndex)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is THIntraLineDiff &&
        other.type == type &&
        other.text == text &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex;
  }
  
  @override
  int get hashCode {
    return Object.hash(type, text, startIndex, endIndex);
  }
}

/// Types of changes for intra-line diffs
enum THIntraLineDiffType {
  /// Text that is unchanged between old and new versions
  equal,
  
  /// Text that was deleted from the old version
  delete,
  
  /// Text that was inserted in the new version
  insert,
}

/// Extension to provide convenient methods for THIntraLineDiffType
extension THIntraLineDiffTypeExtension on THIntraLineDiffType {
  /// Gets a human-readable name for the diff type
  String get displayName {
    switch (this) {
      case THIntraLineDiffType.equal:
        return 'Equal';
      case THIntraLineDiffType.delete:
        return 'Delete';
      case THIntraLineDiffType.insert:
        return 'Insert';
    }
  }
  
  /// Whether this type represents a change
  bool get isChange => this != THIntraLineDiffType.equal;
}

/// A line with detailed intra-line diff information
/// 
/// Extends the concept of a diff line to include character-level differences
/// within the line content. This enables precise highlighting of what exactly
/// changed within a line.
class THIntraLineDiffLine {
  /// The original diff line
  final String oldContent;
  
  /// The modified diff line  
  final String newContent;
  
  /// Detailed character-level differences within the old line
  final List<THIntraLineDiff> oldDiffs;
  
  /// Detailed character-level differences within the new line
  final List<THIntraLineDiff> newDiffs;
  
  /// Line numbers
  final int? oldLineNumber;
  final int? newLineNumber;
  
  const THIntraLineDiffLine({
    required this.oldContent,
    required this.newContent,
    required this.oldDiffs,
    required this.newDiffs,
    this.oldLineNumber,
    this.newLineNumber,
  });
  
  /// Whether this line has intra-line changes
  bool get hasIntraLineChanges {
    return oldDiffs.any((diff) => diff.isChange) || 
           newDiffs.any((diff) => diff.isChange);
  }
  
  /// Get all changed segments in the old line
  List<THIntraLineDiff> get oldChanges {
    return oldDiffs.where((diff) => diff.isChange).toList();
  }
  
  /// Get all changed segments in the new line
  List<THIntraLineDiff> get newChanges {
    return newDiffs.where((diff) => diff.isChange).toList();
  }
  
  @override
  String toString() {
    return 'THIntraLineDiffLine(old: "$oldContent", new: "$newContent", '
           'oldDiffs: ${oldDiffs.length}, newDiffs: ${newDiffs.length})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is THIntraLineDiffLine &&
        other.oldContent == oldContent &&
        other.newContent == newContent &&
        _listsEqual(other.oldDiffs, oldDiffs) &&
        _listsEqual(other.newDiffs, newDiffs) &&
        other.oldLineNumber == oldLineNumber &&
        other.newLineNumber == newLineNumber;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      oldContent,
      newContent,
      Object.hashAll(oldDiffs),
      Object.hashAll(newDiffs),
      oldLineNumber,
      newLineNumber,
    );
  }
  
  static bool _listsEqual(List<THIntraLineDiff> a, List<THIntraLineDiff> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}