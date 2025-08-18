/// Configuration options for diff operations.
/// 
/// This class encapsulates all the configurable parameters that control
/// how text comparison and diff generation behaves. It provides fine-grained
/// control over the diff algorithm, output formatting, and processing options.
/// 
/// The options affect various aspects of diff processing:
/// - Algorithm behavior (timeouts, cleanup options)
/// - Context and formatting (context lines, line numbers, timestamps)
/// - Content processing (whitespace handling, case sensitivity)
/// - Output generation (line separators, numbering)
/// 
/// Default values are chosen to provide good results for most use cases,
/// but can be customized as needed for specific requirements.
/// 
/// Example usage:
/// ```dart
/// // Use default options
/// final result1 = THDiffSuite.compareTexts(text1, text2);
/// 
/// // Customize options
/// final options = THDiffOptions(
///   contextLines: 5,
///   ignoreWhitespace: true,
///   timeout: 2.0,
/// );
/// final result2 = THDiffSuite.compareTexts(text1, text2, options);
/// ```
class THDiffOptions {
  /// Timeout for diff operation in seconds (default: 1.0).
  /// 
  /// This sets the maximum amount of time the diff algorithm will spend
  /// processing before giving up. For very large files or complex diffs,
  /// you may need to increase this value. Setting it too low may result
  /// in incomplete or suboptimal diff results.
  final double timeout;
  
  /// Number of context lines to include around changes (default: 3).
  /// 
  /// Context lines are unchanged lines that appear before and after
  /// each group of changes in the diff output. They help provide context
  /// for understanding where changes occurred. Common values:
  /// - 0: No context (minimal output)
  /// - 3: Standard context (default, good for most cases)
  /// - 5-10: Extended context (helpful for complex changes)
  final int contextLines;
  
  /// Whether to enable semantic cleanup of diffs (default: true).
  /// 
  /// When enabled, the diff algorithm will attempt to make the diff
  /// more readable by merging related changes and reducing noise.
  /// This generally produces better results for human consumption
  /// but may slightly increase processing time.
  final bool enableSemanticCleanup;
  
  /// Whether to enable efficiency cleanup of diffs (default: true).
  /// 
  /// When enabled, the diff algorithm will optimize the diff for
  /// efficiency by removing redundant operations and simplifying
  /// the result. This generally improves both readability and
  /// processing performance.
  final bool enableEfficiencyCleanup;
  
  /// Whether to ignore whitespace differences (default: false).
  /// 
  /// When enabled, differences in whitespace (spaces, tabs, etc.)
  /// will be ignored during comparison. This is useful when comparing
  /// code or documents where whitespace formatting may vary but
  /// content is essentially the same.
  final bool ignoreWhitespace;
  
  /// Whether to ignore case differences (default: false).
  /// 
  /// When enabled, differences in letter case (uppercase vs lowercase)
  /// will be ignored during comparison. This is useful for case-insensitive
  /// comparisons of text content.
  final bool ignoreCase;
  
  /// Custom line separator (default: null - auto-detect).
  /// 
  /// Specifies the line ending character(s) to use when splitting text
  /// into lines. When null, the system will auto-detect based on the
  /// content. Common values:
  /// - null: Auto-detect (recommended)
  /// - '\n': Unix/Linux line endings
  /// - '\r\n': Windows line endings
  /// - '\r': Classic Mac line endings
  final String? lineSeparator;
  
  /// Whether to include line numbers in output (default: true).
  /// 
  /// When enabled, diff output formatters will include line numbers
  /// in their output, making it easier to locate changes in the
  /// original files. Disable this for cleaner output when line
  /// numbers are not needed.
  final bool includeLineNumbers;
  
  /// Whether to include file timestamps in output (default: true).
  /// 
  /// When enabled, diff output formatters will include timestamp
  /// information in file headers. This provides metadata about
  /// when the comparison was performed and can be useful for
  /// tracking and documentation purposes.
  final bool includeTimestamps;
  
  /// Whether to enable intra-line diffing for similar lines (default: true).
  /// 
  /// When enabled, lines that are similar but not identical will be
  /// analyzed for character or word-level differences. This provides
  /// more granular highlighting of what exactly changed within a line
  /// rather than marking entire lines as additions/deletions.
  final bool enableIntraLineDiff;
  
  /// Whether to perform word-level diffing instead of character-level (default: false).
  /// 
  /// When enableIntraLineDiff is true, this option controls whether
  /// intra-line diffs operate at the word level (true) or character
  /// level (false). Word-level diffing is more readable for text content,
  /// while character-level is more precise for code.
  final bool wordLevelDiff;
  
  /// Similarity threshold for intra-line diffing (default: 0.3).
  /// 
  /// Controls how similar two lines must be (0.0 to 1.0) before
  /// intra-line diffing is applied. Higher values mean lines must be
  /// more similar to trigger word/character-level analysis. Lower
  /// values will analyze more line pairs but may produce noise.
  final double similarityThreshold;
  
  const THDiffOptions({
    this.timeout = 1.0,
    this.contextLines = 3,
    this.enableSemanticCleanup = true,
    this.enableEfficiencyCleanup = true,
    this.ignoreWhitespace = false,
    this.ignoreCase = false,
    this.lineSeparator,
    this.includeLineNumbers = true,
    this.includeTimestamps = true,
    this.enableIntraLineDiff = true,
    this.wordLevelDiff = false,
    this.similarityThreshold = 0.3,
  });
  
  /// Creates a copy of this options object with some fields changed.
  /// 
  /// This method provides an immutable way to create a new THDiffOptions
  /// instance with modified settings while preserving all other options.
  /// This is useful for creating variations of a base configuration.
  /// 
  /// Parameters (all optional):
  /// - [timeout]: New timeout value
  /// - [contextLines]: New context lines count
  /// - [enableSemanticCleanup]: New semantic cleanup setting
  /// - [enableEfficiencyCleanup]: New efficiency cleanup setting
  /// - [ignoreWhitespace]: New whitespace handling setting
  /// - [ignoreCase]: New case sensitivity setting
  /// - [lineSeparator]: New line separator
  /// - [includeLineNumbers]: New line numbers setting
  /// - [includeTimestamps]: New timestamps setting
  /// - [enableIntraLineDiff]: New intra-line diff setting
  /// - [wordLevelDiff]: New word-level diff setting
  /// - [similarityThreshold]: New similarity threshold
  /// 
  /// Returns a new [THDiffOptions] instance with the specified fields updated
  /// and all other fields copied from the current instance.
  /// 
  /// Example:
  /// ```dart
  /// final baseOptions = THDiffOptions();
  /// final customOptions = baseOptions.copyWith(
  ///   contextLines: 5,
  ///   ignoreWhitespace: true,
  ///   enableIntraLineDiff: true,
  ///   wordLevelDiff: true,
  /// );
  /// ```
  THDiffOptions copyWith({
    double? timeout,
    int? contextLines,
    bool? enableSemanticCleanup,
    bool? enableEfficiencyCleanup,
    bool? ignoreWhitespace,
    bool? ignoreCase,
    String? lineSeparator,
    bool? includeLineNumbers,
    bool? includeTimestamps,
    bool? enableIntraLineDiff,
    bool? wordLevelDiff,
    double? similarityThreshold,
  }) {
    return THDiffOptions(
      timeout: timeout ?? this.timeout,
      contextLines: contextLines ?? this.contextLines,
      enableSemanticCleanup: enableSemanticCleanup ?? this.enableSemanticCleanup,
      enableEfficiencyCleanup: enableEfficiencyCleanup ?? this.enableEfficiencyCleanup,
      ignoreWhitespace: ignoreWhitespace ?? this.ignoreWhitespace,
      ignoreCase: ignoreCase ?? this.ignoreCase,
      lineSeparator: lineSeparator ?? this.lineSeparator,
      includeLineNumbers: includeLineNumbers ?? this.includeLineNumbers,
      includeTimestamps: includeTimestamps ?? this.includeTimestamps,
      enableIntraLineDiff: enableIntraLineDiff ?? this.enableIntraLineDiff,
      wordLevelDiff: wordLevelDiff ?? this.wordLevelDiff,
      similarityThreshold: similarityThreshold ?? this.similarityThreshold,
    );
  }
  
  @override
  String toString() {
    return 'THDiffOptions('
        'timeout: $timeout, '
        'contextLines: $contextLines, '
        'enableSemanticCleanup: $enableSemanticCleanup, '
        'enableEfficiencyCleanup: $enableEfficiencyCleanup, '
        'ignoreWhitespace: $ignoreWhitespace, '
        'ignoreCase: $ignoreCase, '
        'lineSeparator: $lineSeparator, '
        'includeLineNumbers: $includeLineNumbers, '
        'includeTimestamps: $includeTimestamps, '
        'enableIntraLineDiff: $enableIntraLineDiff, '
        'wordLevelDiff: $wordLevelDiff, '
        'similarityThreshold: $similarityThreshold'
        ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is THDiffOptions &&
        other.timeout == timeout &&
        other.contextLines == contextLines &&
        other.enableSemanticCleanup == enableSemanticCleanup &&
        other.enableEfficiencyCleanup == enableEfficiencyCleanup &&
        other.ignoreWhitespace == ignoreWhitespace &&
        other.ignoreCase == ignoreCase &&
        other.lineSeparator == lineSeparator &&
        other.includeLineNumbers == includeLineNumbers &&
        other.includeTimestamps == includeTimestamps &&
        other.enableIntraLineDiff == enableIntraLineDiff &&
        other.wordLevelDiff == wordLevelDiff &&
        other.similarityThreshold == similarityThreshold;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      timeout,
      contextLines,
      enableSemanticCleanup,
      enableEfficiencyCleanup,
      ignoreWhitespace,
      ignoreCase,
      lineSeparator,
      includeLineNumbers,
      includeTimestamps,
      enableIntraLineDiff,
      wordLevelDiff,
      similarityThreshold,
    );
  }
}