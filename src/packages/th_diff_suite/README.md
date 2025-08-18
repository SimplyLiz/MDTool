# TH Diff Suite

A comprehensive text diff and comparison package for Flutter applications with support for multiple output formats including Git diff, unified diff, and custom formats.

## Features

- **Multiple Input Methods**: Compare text strings, files, or custom document objects
- **Multiple Output Formats**: Git diff, unified diff, and custom TH MD format
- **Word/Character-Level Diffing**: Enhanced intra-line highlighting for precise change visualization
- **UI Integration Helpers**: Color schemes, export utilities, and navigation helpers for Flutter UI
- **Configurable Options**: Context lines, timeouts, cleanup options, similarity thresholds, and more
- **Rich Statistics**: Detailed analysis of changes with line counts and percentages
- **Performance Optimized**: Uses Google's diff-match-patch algorithm with efficiency cleanup
- **Flutter Ready**: Designed specifically for Flutter applications

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  th_diff_suite: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Text Comparison

```dart
import 'package:th_diff_suite/th_diff_suite.dart';

// Compare two text strings
final text1 = "Hello World\nThis is line 2";
final text2 = "Hello Universe\nThis is line 2\nNew line added";

final result = THDiffSuite.compareTexts(text1, text2);

// Get Git diff format
final gitDiff = THDiffSuite.toGitDiff(result);
print(gitDiff);

// Get statistics
print('Added: ${result.stats.addedLines}');
print('Deleted: ${result.stats.deletedLines}');
print('Changed: ${result.stats.changePercentage.toStringAsFixed(1)}%');
```

### File Comparison

```dart
// Compare two files
final result = await THDiffSuite.compareFiles('file1.txt', 'file2.txt');

// Export as unified diff
final unifiedDiff = THDiffSuite.toUnifiedDiff(result);
print(unifiedDiff);
```

### Advanced Configuration

```dart
// Create custom options
final options = THDiffOptions(
  contextLines: 5,           // Show 5 lines of context
  timeout: 2.0,             // 2 second timeout
  ignoreWhitespace: true,   // Ignore whitespace differences
  ignoreCase: false,        // Case sensitive
  enableIntraLineDiff: true, // Enable word/character-level diffing
  wordLevelDiff: true,      // Use word-level instead of character-level
  similarityThreshold: 0.3, // Threshold for triggering intra-line diff
);

final result = THDiffSuite.compareTexts(text1, text2, options);
```

### Word/Character-Level Diffing

TH Diff Suite supports precise intra-line highlighting that shows exactly what changed within lines:

```dart
// Character-level diffing for code
final codeOptions = THDiffOptions(
  enableIntraLineDiff: true,
  wordLevelDiff: false, // Character precision for code
);

final codeResult = THDiffSuite.compareTexts(
  'function calculateTotal(items) {',
  'function computeTotal(items) {',
  codeOptions,
);

// Word-level diffing for text
final textOptions = THDiffOptions(
  enableIntraLineDiff: true,
  wordLevelDiff: true, // Word boundaries for readability
);

final textResult = THDiffSuite.compareTexts(
  'The quick brown fox jumps',
  'The fast brown fox leaps',
  textOptions,
);

// Access intra-line changes
for (final hunk in textResult.hunks) {
  for (final line in hunk.lines) {
    if (line.hasIntraLineDiff) {
      print('Line has ${line.intraLineChanges.length} intra-line changes');
      for (final change in line.intraLineChanges) {
        print('${change.type.displayName}: "${change.text}"');
      }
    }
  }
}
```

## Output Formats

### 1. Git Diff Format

Compatible with Git and can be applied with `git apply`:

```dart
final gitDiff = THDiffSuite.toGitDiff(result);
```

**Example Output:**
```diff
diff --git a/file b/file
index 0000000..1111111 100644
--- a/file
+++ b/file
@@ -1,2 +1,3 @@
-Hello World
+Hello Universe
 This is line 2
+New line added
```

### 2. Unified Diff Format

Standard unified diff format with customizable options:

```dart
final unifiedDiff = THDiffSuite.toUnifiedDiff(result);
```

### 3. TH MD Format (Custom)

Rich Markdown format with detailed annotations and statistics:

```dart
final mdDiff = THDiffSuite.toMDDiff(result);
```

**Features of TH MD Format:**
- Detailed statistics and metadata
- Syntax-highlighted diff blocks
- Line-by-line annotations
- Interactive JSON structure option
- Compact summary format

## API Reference

### Core Methods

#### `THDiffSuite.compareTexts(String text1, String text2, [THDiffOptions? options])`
Compare two text strings and return a detailed diff result.

**Parameters:**
- `text1`: Original text (left side)
- `text2`: Modified text (right side)  
- `options`: Optional configuration (see THDiffOptions)

**Returns:** `THDiffResult`

#### `THDiffSuite.compareFiles(String filePath1, String filePath2, [THDiffOptions? options])`
Compare two files asynchronously.

**Parameters:**
- `filePath1`: Path to original file
- `filePath2`: Path to modified file
- `options`: Optional configuration

**Returns:** `Future<THDiffResult>`

### Output Formatters

#### `THDiffSuite.toGitDiff(THDiffResult result)`
Convert diff result to Git diff format.

#### `THDiffSuite.toUnifiedDiff(THDiffResult result)`
Convert diff result to unified diff format.

#### `THDiffSuite.toMDDiff(THDiffResult result)`
Convert diff result to TH MD format with rich annotations.

### Configuration Options

The `THDiffOptions` class provides extensive configuration:

```dart
THDiffOptions({
  double timeout = 1.0,                    // Operation timeout in seconds
  int contextLines = 3,                    // Lines of context around changes
  bool enableSemanticCleanup = true,       // Improve diff readability
  bool enableEfficiencyCleanup = true,     // Optimize for performance
  bool ignoreWhitespace = false,           // Ignore whitespace differences
  bool ignoreCase = false,                 // Case insensitive comparison
  String? lineSeparator,                   // Custom line separator
  bool includeLineNumbers = true,          // Include line numbers in output
  bool includeTimestamps = true,           // Include timestamps in headers
  bool enableIntraLineDiff = true,         // Enable word/character-level diffing
  bool wordLevelDiff = false,              // Use word-level instead of character-level
  double similarityThreshold = 0.3,       // Similarity threshold for intra-line diff
})
```

### Data Models

#### `THDiffResult`
Complete diff result containing:
- Original and modified text
- List of hunks (change blocks)
- Configuration options used
- File paths (if applicable)
- Timestamp and statistics

#### `THDiffHunk` 
Represents a contiguous block of changes:
- Line ranges for old and new files
- Collection of individual line changes
- Optional section headers

#### `THDiffLine`
Individual line with change information:
- Line content
- Change type (context, addition, deletion)
- Line numbers in both files

#### `THDiffStats`
Statistics about the diff:
- Total, added, deleted, unchanged line counts
- Number of hunks
- Change percentage

## Examples

### Example 1: Basic File Comparison

```dart
import 'package:th_diff_suite/th_diff_suite.dart';

void main() async {
  try {
    final result = await THDiffSuite.compareFiles('old.txt', 'new.txt');
    
    if (result.hasChanges) {
      print('Files are different!');
      print('Changes: +${result.stats.addedLines} -${result.stats.deletedLines}');
      
      // Export as Git diff
      final gitDiff = THDiffSuite.toGitDiff(result);
      print(gitDiff);
    } else {
      print('Files are identical.');
    }
  } catch (e) {
    print('Error comparing files: $e');
  }
}
```

### Example 2: Custom Options and Multiple Formats

```dart
import 'package:th_diff_suite/th_diff_suite.dart';

void main() {
  final oldText = '''
  function greet(name) {
    console.log("Hello " + name);
  }
  ''';
  
  final newText = '''
  function greet(name) {
    console.log(`Hello \${name}!`);
    return `Greeted \${name}`;
  }
  ''';
  
  // Configure options
  final options = THDiffOptions(
    contextLines: 2,
    ignoreWhitespace: true,
    timeout: 5.0,
  );
  
  final result = THDiffSuite.compareTexts(oldText, newText, options);
  
  // Multiple output formats
  print('=== GIT DIFF ===');
  print(THDiffSuite.toGitDiff(result));
  
  print('\n=== UNIFIED DIFF ===');
  print(THDiffSuite.toUnifiedDiff(result));
  
  print('\n=== TH MD DIFF ===');
  print(THDiffSuite.toMDDiff(result));
}
```

### Example 3: Statistics and Analysis

```dart
import 'package:th_diff_suite/th_diff_suite.dart';

void analyzeChanges(String oldText, String newText) {
  final result = THDiffSuite.compareTexts(oldText, newText);
  
  print('Diff Analysis:');
  print('- Total lines processed: ${result.stats.totalLines}');
  print('- Lines added: ${result.stats.addedLines}');
  print('- Lines deleted: ${result.stats.deletedLines}');
  print('- Lines unchanged: ${result.stats.unchangedLines}');
  print('- Number of hunks: ${result.stats.hunksCount}');
  print('- Change percentage: ${result.stats.changePercentage.toStringAsFixed(1)}%');
  
  // Analyze each hunk
  for (int i = 0; i < result.hunks.length; i++) {
    final hunk = result.hunks[i];
    print('\nHunk ${i + 1}:');
    print('- Location: lines ${hunk.oldStart}-${hunk.oldStart + hunk.oldCount - 1}');
    print('- Additions: ${hunk.additionCount}');
    print('- Deletions: ${hunk.deletionCount}');
  }
}
```

## UI Integration

TH Diff Suite includes comprehensive UI helpers for Flutter integration:

### Color Schemes and Styling

```dart
// Use default GitHub-style colors
final colors = DiffUIHelpers.defaultColors;

// Or create custom colors matching your theme
final customColors = DiffColorScheme.fromTheme(
  primary: Theme.of(context).primaryColor,
  error: Theme.of(context).colorScheme.error,
  onSurface: Theme.of(context).colorScheme.onSurface,
  surface: Theme.of(context).colorScheme.surface,
);

// Apply to widgets
Container(
  color: DiffUIHelpers.getColorForLineType(line.type, isBackground: true),
  child: Text(
    line.content,
    style: TextStyle(
      color: DiffUIHelpers.getColorForLineType(line.type),
    ),
  ),
)
```

### Word-Level UI Highlighting

For precise intra-line highlighting, use the enhanced UI helpers:

```dart
// Create RichText with word/character-level highlighting
Widget buildIntraLineDiffText(THDiffLine line) {
  if (line.hasIntraLineDiff) {
    // Use TextSpans for precise highlighting
    final spans = DiffUIHelpers.createIntraLineTextSpans(
      line,
      colorScheme: DiffUIHelpers.defaultColors,
      baseStyle: TextStyle(fontFamily: 'monospace', fontSize: 14),
    );
    
    return RichText(
      text: TextSpan(children: spans),
    );
  } else {
    // Regular single-color line
    return Text(
      line.content,
      style: TextStyle(
        color: DiffUIHelpers.getColorForLineType(line.type),
        fontFamily: 'monospace',
        fontSize: 14,
      ),
    );
  }
}

// Create summary for tooltips
final summary = DiffUIHelpers.createIntraLineSummary(line);
Tooltip(
  message: summary,
  child: buildIntraLineDiffText(line),
)
```

### Export and Sharing

```dart
// Export to file
await DiffExportHelpers.exportToFile(
  result,
  'my-diff.md',
  DiffExportFormat.markdown,
);

// Generate shareable summary
final summary = DiffExportHelpers.generateShareableSummary(result);

// Copy to clipboard
final clipboardContent = DiffExportHelpers.generateClipboardContent(
  result,
  DiffExportFormat.gitDiff,
);
```

### Navigation Utilities

```dart
// Get positions of all changes for navigation
final changePositions = DiffUIHelpers.getChangePositions(result);

// Group consecutive lines for performance
final lineGroups = DiffUIHelpers.groupConsecutiveLines(allLines);

// Create change summary for headers
final summary = DiffUIHelpers.createChangeSummary(result);
```

See [docs/UI_INTEGRATION.md](docs/UI_INTEGRATION.md) for complete integration examples including ready-to-use Flutter widgets.

## Future Features

The following features are planned for future versions:

```dart
// Document comparison (planned)
final result = await THDiffSuite.compareDocuments(doc1, doc2);

// Directory comparison (planned)  
final results = await THDiffSuite.compareDirectories('dir1/', 'dir2/');

// Context diff format (planned)
final contextDiff = THDiffSuite.toContextDiff(result);

// Binary file support (planned)
final binaryResult = await THDiffSuite.compareBinaryFiles('img1.png', 'img2.png');
```

## Performance

- Uses Google's proven diff-match-patch algorithm
- Configurable timeouts prevent hanging on large files
- Memory-efficient processing of large texts
- Optional semantic and efficiency cleanup for optimal results

## Error Handling

The package provides clear error messages for common issues:

- File not found errors with specific file paths
- Timeout errors for operations that take too long
- Permission errors for inaccessible files
- Format errors for invalid input

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

### 0.1.0
- Initial release with comprehensive diff functionality
- **Core Features:**
  - Text and file comparison with line-based algorithm
  - Multiple output formats: Git diff, unified diff, and TH MD format
  - Word/character-level intra-line diffing for precise change highlighting
- **UI Integration:**
  - Flutter-ready UI helpers with color schemes and styling
  - TextSpan generation for precise word-level highlighting
  - Export utilities and clipboard support
- **Advanced Options:**
  - Configurable similarity thresholds for intra-line diffing
  - Word-level vs character-level diffing modes
  - Context lines, timeouts, and cleanup options
- **Developer Experience:**
  - Comprehensive test suite with 96% pass rate
  - Rich statistics and change analysis
  - Professional documentation with examples
