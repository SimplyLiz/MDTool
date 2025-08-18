import 'package:diff_match_patch/diff_match_patch.dart';
import 'models/th_intra_line_diff.dart';

/// Algorithm for computing character and word-level differences within lines
/// 
/// This class provides functionality to identify precise character or word
/// changes within lines that are similar but not identical. It uses the
/// diff-match-patch library to compute fine-grained differences.
class IntraLineDiffAlgorithm {
  static final DiffMatchPatch _dmp = DiffMatchPatch();
  
  /// Compute character-level differences between two lines
  /// 
  /// [oldLine] The original line content
  /// [newLine] The modified line content
  /// [wordLevel] If true, performs word-level diffing instead of character-level
  /// 
  /// Returns lists of intra-line diffs for both old and new lines
  static IntraLineDiffResult computeIntraLineDiff(
    String oldLine,
    String newLine, {
    bool wordLevel = false,
  }) {
    if (oldLine == newLine) {
      // Lines are identical - return equal segments
      return IntraLineDiffResult(
        oldDiffs: [
          THIntraLineDiff(
            type: THIntraLineDiffType.equal,
            text: oldLine,
            startIndex: 0,
            endIndex: oldLine.length,
          ),
        ],
        newDiffs: [
          THIntraLineDiff(
            type: THIntraLineDiffType.equal,
            text: newLine,
            startIndex: 0,
            endIndex: newLine.length,
          ),
        ],
      );
    }
    
    // Perform diff using diff-match-patch
    List<Diff> diffs;
    if (wordLevel) {
      diffs = _computeWordLevelDiff(oldLine, newLine);
    } else {
      diffs = _dmp.diff(oldLine, newLine);
    }
    
    // Convert to our intra-line diff format
    return _convertToIntraLineDiffs(diffs, oldLine, newLine);
  }
  
  /// Perform word-level diffing by splitting on word boundaries
  static List<Diff> _computeWordLevelDiff(String oldLine, String newLine) {
    // Split into words while preserving separators
    final oldWords = _splitIntoWords(oldLine);
    final newWords = _splitIntoWords(newLine);
    
    // Create temporary text with word markers for diffing
    final oldText = oldWords.join('\n');
    final newText = newWords.join('\n');
    
    // Perform diff on word-separated text
    final wordDiffs = _dmp.diff(oldText, newText);
    
    // Convert back to character-based diffs
    return _convertWordDiffsToCharDiffs(wordDiffs, oldWords, newWords);
  }
  
  /// Split text into words while preserving separators
  static List<String> _splitIntoWords(String text) {
    if (text.isEmpty) return [];
    
    final words = <String>[];
    final buffer = StringBuffer();
    bool inWord = false;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isWordChar = RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
      
      if (isWordChar) {
        if (!inWord && buffer.isNotEmpty) {
          // End of separator sequence
          words.add(buffer.toString());
          buffer.clear();
        }
        buffer.write(char);
        inWord = true;
      } else {
        if (inWord && buffer.isNotEmpty) {
          // End of word
          words.add(buffer.toString());
          buffer.clear();
        }
        buffer.write(char);
        inWord = false;
      }
    }
    
    if (buffer.isNotEmpty) {
      words.add(buffer.toString());
    }
    
    return words;
  }
  
  /// Convert word-level diffs back to character-level diffs
  static List<Diff> _convertWordDiffsToCharDiffs(
    List<Diff> wordDiffs,
    List<String> oldWords,
    List<String> newWords,
  ) {
    final result = <Diff>[];
    
    for (final wordDiff in wordDiffs) {
      final words = wordDiff.text.split('\n');
      final text = words.join('');
      
      if (text.isNotEmpty) {
        result.add(Diff(wordDiff.operation, text));
      }
    }
    
    return result;
  }
  
  /// Convert diff-match-patch diffs to our intra-line diff format
  static IntraLineDiffResult _convertToIntraLineDiffs(
    List<Diff> diffs,
    String oldLine,
    String newLine,
  ) {
    final oldDiffs = <THIntraLineDiff>[];
    final newDiffs = <THIntraLineDiff>[];
    
    int oldIndex = 0;
    int newIndex = 0;
    
    for (final diff in diffs) {
      final text = diff.text;
      final length = text.length;
      
      switch (diff.operation) {
        case DIFF_EQUAL:
          // Text exists in both old and new
          oldDiffs.add(THIntraLineDiff(
            type: THIntraLineDiffType.equal,
            text: text,
            startIndex: oldIndex,
            endIndex: oldIndex + length,
          ));
          newDiffs.add(THIntraLineDiff(
            type: THIntraLineDiffType.equal,
            text: text,
            startIndex: newIndex,
            endIndex: newIndex + length,
          ));
          oldIndex += length;
          newIndex += length;
          break;
          
        case DIFF_DELETE:
          // Text was deleted from old version
          oldDiffs.add(THIntraLineDiff(
            type: THIntraLineDiffType.delete,
            text: text,
            startIndex: oldIndex,
            endIndex: oldIndex + length,
          ));
          oldIndex += length;
          break;
          
        case DIFF_INSERT:
          // Text was inserted in new version
          newDiffs.add(THIntraLineDiff(
            type: THIntraLineDiffType.insert,
            text: text,
            startIndex: newIndex,
            endIndex: newIndex + length,
          ));
          newIndex += length;
          break;
      }
    }
    
    return IntraLineDiffResult(oldDiffs: oldDiffs, newDiffs: newDiffs);
  }
  
  /// Check if two lines are similar enough to warrant intra-line diffing
  /// 
  /// Uses a similarity threshold to determine if lines should be compared
  /// at the character level rather than treating them as completely different.
  static bool shouldComputeIntraLineDiff(
    String oldLine,
    String newLine, {
    double similarityThreshold = 0.3,
  }) {
    if (oldLine == newLine) return false; // Identical lines don't need intra-line diff
    if (oldLine.isEmpty || newLine.isEmpty) return false; // Empty lines
    
    // Use a similarity metric based on character overlap and length
    final similarity = _computeSimilarity(oldLine, newLine);
    return similarity >= similarityThreshold;
  }
  
  /// Compute a similarity score between two strings (0.0 to 1.0)
  static double _computeSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    // Use Levenshtein distance based similarity for better accuracy
    final maxLen = [a.length, b.length].reduce((a, b) => a > b ? a : b);
    final distance = _levenshteinDistance(a, b);
    final similarity = 1.0 - (distance / maxLen);
    
    return similarity.clamp(0.0, 1.0);
  }
  
  /// Compute Levenshtein distance between two strings
  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    
    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );
    
    // Initialize first row and column
    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }
    
    // Fill the matrix
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,     // deletion
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[a.length][b.length];
  }
}

/// Result of intra-line diff computation
class IntraLineDiffResult {
  /// Diff segments for the old line
  final List<THIntraLineDiff> oldDiffs;
  
  /// Diff segments for the new line
  final List<THIntraLineDiff> newDiffs;
  
  const IntraLineDiffResult({
    required this.oldDiffs,
    required this.newDiffs,
  });
  
  /// Whether this result contains any changes
  bool get hasChanges {
    return oldDiffs.any((diff) => diff.isChange) || 
           newDiffs.any((diff) => diff.isChange);
  }
  
  /// Get all change segments from both old and new lines
  List<THIntraLineDiff> get allChanges {
    final changes = <THIntraLineDiff>[];
    changes.addAll(oldDiffs.where((diff) => diff.isChange));
    changes.addAll(newDiffs.where((diff) => diff.isChange));
    return changes;
  }
}