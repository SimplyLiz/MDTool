import 'package:th_diff_suite/th_diff_suite.dart';

void main() async {
  print('=== TH Diff Suite Example ===\n');
  
  // Example 1: Basic text comparison
  await basicTextComparison();
  
  // Example 2: File comparison (commented out since files don't exist)
  // await fileComparison();
  
  // Example 3: Advanced configuration
  await advancedConfiguration();
  
  // Example 4: Multiple output formats
  await multipleFormats();
  
  // Example 5: Statistics analysis
  await statisticsAnalysis();
}

/// Example 1: Basic text comparison
Future<void> basicTextComparison() async {
  print('--- Example 1: Basic Text Comparison ---');
  
  final text1 = '''Hello World
This is line 2
Original content here''';
  
  final text2 = '''Hello Universe
This is line 2
Modified content here
New line added''';
  
  final result = THDiffSuite.compareTexts(text1, text2);
  
  print('Has changes: ${result.hasChanges}');
  print('Added lines: ${result.stats.addedLines}');
  print('Deleted lines: ${result.stats.deletedLines}');
  print('Change percentage: ${result.stats.changePercentage.toStringAsFixed(1)}%');
  
  print('\nGit diff output:');
  print(THDiffSuite.toGitDiff(result));
  print('');
}

/// Example 2: File comparison (create test files first)
Future<void> fileComparison() async {
  print('--- Example 2: File Comparison ---');
  
  try {
    final result = await THDiffSuite.compareFiles('old.txt', 'new.txt');
    
    if (result.hasChanges) {
      print('Files are different!');
      print('Changes: +${result.stats.addedLines} -${result.stats.deletedLines}');
      
      final unifiedDiff = THDiffSuite.toUnifiedDiff(result);
      print('\nUnified diff:');
      print(unifiedDiff);
    } else {
      print('Files are identical.');
    }
  } catch (e) {
    print('Error comparing files: $e');
  }
  print('');
}

/// Example 3: Advanced configuration
Future<void> advancedConfiguration() async {
  print('--- Example 3: Advanced Configuration ---');
  
  final oldCode = '''function calculateTotal(items) {
  let total = 0;
  for (let i = 0; i < items.length; i++) {
    total += items[i].price;
  }
  return total;
}''';
  
  final newCode = '''function calculateTotal(items) {
  return items.reduce((total, item) => total + item.price, 0);
}

function calculateTax(total, rate = 0.08) {
  return total * rate;
}''';
  
  // Configure custom options
  final options = THDiffOptions(
    contextLines: 2,
    timeout: 5.0,
    enableSemanticCleanup: true,
    enableEfficiencyCleanup: true,
    ignoreWhitespace: false,
  );
  
  final result = THDiffSuite.compareTexts(oldCode, newCode, options);
  
  print('Configuration used:');
  print('- Context lines: ${options.contextLines}');
  print('- Timeout: ${options.timeout}s');
  print('- Semantic cleanup: ${options.enableSemanticCleanup}');
  
  print('\nResults:');
  print('- Hunks: ${result.stats.hunksCount}');
  print('- Changes: ${result.stats.changedLines}');
  print('');
}

/// Example 4: Multiple output formats
Future<void> multipleFormats() async {
  print('--- Example 4: Multiple Output Formats ---');
  
  final original = '''# My Document
## Section 1
Original content

## Section 2  
More content''';
  
  final modified = '''# My Document
## Section 1
Updated content with changes

## Section 2  
More content

## New Section
Additional content added''';
  
  final result = THDiffSuite.compareTexts(original, modified);
  
  print('=== Git Diff Format ===');
  print(THDiffSuite.toGitDiff(result));
  
  print('=== Unified Diff Format ===');
  print(THDiffSuite.toUnifiedDiff(result));
  
  print('=== TH MD Diff Format (Custom) ===');
  final mdDiff = THDiffSuite.toMDDiff(result);
  // Print first few lines to avoid too much output
  final lines = mdDiff.split('\n');
  for (int i = 0; i < 20 && i < lines.length; i++) {
    print(lines[i]);
  }
  if (lines.length > 20) {
    print('... (output truncated)');
  }
  print('');
}

/// Example 5: Statistics analysis
Future<void> statisticsAnalysis() async {
  print('--- Example 5: Statistics Analysis ---');
  
  final oldText = '''Line 1
Line 2  
Line 3
Line 4
Line 5''';
  
  final newText = '''Line 1
Modified Line 2
Line 3
Line 5
New Line 6
New Line 7''';
  
  final result = THDiffSuite.compareTexts(oldText, newText);
  
  print('Detailed Statistics:');
  print('- Total lines: ${result.stats.totalLines}');
  print('- Added lines: ${result.stats.addedLines}');
  print('- Deleted lines: ${result.stats.deletedLines}');
  print('- Changed lines: ${result.stats.changedLines}');
  print('- Unchanged lines: ${result.stats.unchangedLines}');
  print('- Number of hunks: ${result.stats.hunksCount}');
  print('- Change percentage: ${result.stats.changePercentage.toStringAsFixed(2)}%');
  
  print('\nHunk Analysis:');
  for (int i = 0; i < result.hunks.length; i++) {
    final hunk = result.hunks[i];
    print('Hunk ${i + 1}:');
    print('  - Old range: ${hunk.oldStart}-${hunk.oldStart + hunk.oldCount - 1}');
    print('  - New range: ${hunk.newStart}-${hunk.newStart + hunk.newCount - 1}');
    print('  - Additions: ${hunk.additionCount}');
    print('  - Deletions: ${hunk.deletionCount}');
    print('  - Total changes: ${hunk.changedLines.length}');
  }
  
  print('\nIndividual Changes:');
  final changedLines = result.allChangedLines;
  for (int i = 0; i < changedLines.length && i < 5; i++) {
    final line = changedLines[i];
    final type = line.type == THDiffLineType.addition ? 'Added' : 'Deleted';
    final lineNum = line.type == THDiffLineType.addition 
        ? line.newLineNumber ?? '?'
        : line.oldLineNumber ?? '?';
    print('  $type at line $lineNum: "${line.content}"');
  }
  
  if (changedLines.length > 5) {
    print('  ... and ${changedLines.length - 5} more changes');
  }
  
  print('');
}