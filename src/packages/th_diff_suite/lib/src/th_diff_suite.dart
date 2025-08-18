import 'dart:io';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:path/path.dart' as path;

import 'models/th_diff_result.dart';
import 'models/th_diff_options.dart';
import 'formatters/git_diff_formatter.dart';
import 'formatters/unified_diff_formatter.dart';
import 'formatters/th_md_diff_formatter.dart';

/// Main API class for TH Diff Suite functionality.
/// 
/// THDiffSuite provides comprehensive text comparison capabilities with support
/// for multiple output formats. It handles both string and file comparisons,
/// offering various formatting options including Git diff, unified diff, and
/// custom Markdown diff formats.
/// 
/// This class is abstract and provides static methods for all operations,
/// making it convenient to use without instantiation.
/// 
/// Example usage:
/// ```dart
/// // Compare two strings
/// final result = THDiffSuite.compareTexts(oldText, newText);
/// print('Found ${result.stats.changedLines} changed lines');
/// 
/// // Compare files
/// final fileResult = await THDiffSuite.compareFiles('old.txt', 'new.txt');
/// 
/// // Generate different output formats
/// final gitDiff = THDiffSuite.toGitDiff(result);
/// final unifiedDiff = THDiffSuite.toUnifiedDiff(result);
/// ```
abstract class THDiffSuite {
  /// Compares two text strings and returns a comprehensive diff result.
  /// 
  /// This method performs a line-by-line comparison of the input texts and
  /// generates a detailed diff result containing hunks, statistics, and
  /// formatting information.
  /// 
  /// Parameters:
  /// - [text1]: The original text (baseline for comparison)
  /// - [text2]: The modified text (target for comparison)
  /// - [options]: Optional configuration settings that control diff behavior,
  ///   such as context lines, timeout, and formatting options
  /// 
  /// Returns a [THDiffResult] containing:
  /// - List of hunks representing the changes
  /// - Statistics about additions, deletions, and unchanged lines
  /// - Metadata including timestamp and options used
  /// 
  /// Example:
  /// ```dart
  /// const original = 'Line 1\nLine 2\nLine 3';
  /// const modified = 'Line 1\nModified Line 2\nLine 3';
  /// 
  /// final result = THDiffSuite.compareTexts(original, modified);
  /// print('Changes found: ${result.hasChanges}');
  /// print('Hunks: ${result.hunks.length}');
  /// print('Lines added: ${result.stats.addedLines}');
  /// ```
  static THDiffResult compareTexts(
    String text1, 
    String text2, [
    THDiffOptions? options,
  ]) {
    options ??= THDiffOptions();
    
    // Split texts into lines, handling empty strings properly
    final lines1 = text1.isEmpty ? <String>[] : text1.split('\n');
    final lines2 = text2.isEmpty ? <String>[] : text2.split('\n');
    
    return THDiffResult.fromLineComparison(
      lines1,
      lines2,
      originalText: text1,
      modifiedText: text2,
      options: options,
    );
  }
  
  /// Compares two files and returns a comprehensive diff result.
  /// 
  /// This method reads the contents of two files and performs a line-by-line
  /// comparison, generating a detailed diff result with hunks, statistics, and
  /// metadata. The file paths are automatically extracted and stored in the result.
  /// 
  /// Parameters:
  /// - [filePath1]: Path to the original file (baseline for comparison)
  /// - [filePath2]: Path to the modified file (target for comparison)  
  /// - [options]: Optional configuration settings that control diff behavior
  /// 
  /// Returns a [THDiffResult] containing the same information as [compareTexts]
  /// but with additional file path metadata.
  /// 
  /// Throws:
  /// - [FileSystemException] if either file does not exist or cannot be read
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await THDiffSuite.compareFiles(
  ///     'documents/v1.md', 
  ///     'documents/v2.md'
  ///   );
  ///   print('Comparing ${result.filePath1} -> ${result.filePath2}');
  ///   print('Found ${result.stats.changedLines} changes');
  /// } catch (e) {
  ///   print('Error reading files: $e');
  /// }
  /// ```
  static Future<THDiffResult> compareFiles(
    String filePath1,
    String filePath2, [
    THDiffOptions? options,
  ]) async {
    final file1 = File(filePath1);
    final file2 = File(filePath2);
    
    if (!await file1.exists()) {
      throw FileSystemException('File not found', filePath1);
    }
    
    if (!await file2.exists()) {
      throw FileSystemException('File not found', filePath2);
    }
    
    final text1 = await file1.readAsString();
    final text2 = await file2.readAsString();
    
    final result = compareTexts(text1, text2, options);
    
    return result.copyWith(
      filePath1: path.basename(filePath1),
      filePath2: path.basename(filePath2),
    );
  }
  
  /// Converts a diff result to Git diff format.
  /// 
  /// This method formats the diff result using Git's standard diff output format,
  /// which includes file headers, hunk headers, and line-by-line changes with
  /// appropriate prefixes (-, +, space for context).
  /// 
  /// Parameters:
  /// - [result]: The diff result to format
  /// 
  /// Returns a string containing the Git-formatted diff output.
  /// 
  /// Example:
  /// ```dart
  /// final result = THDiffSuite.compareTexts(oldText, newText);
  /// final gitDiff = THDiffSuite.toGitDiff(result);
  /// print(gitDiff);
  /// // Output:
  /// // diff --git a/file1 b/file2
  /// // index 1234567..abcdefg 100644
  /// // --- a/file1
  /// // +++ b/file2
  /// // @@ -1,3 +1,3 @@
  /// //  line 1
  /// // -old line 2
  /// // +new line 2
  /// //  line 3
  /// ```
  static String toGitDiff(THDiffResult result) {
    return GitDiffFormatter.format(result);
  }
  
  /// Converts a diff result to unified diff format.
  /// 
  /// This method formats the diff result using the standard unified diff format,
  /// which is similar to Git diff but without Git-specific headers. It includes
  /// file headers with timestamps, hunk headers, and line changes.
  /// 
  /// Parameters:
  /// - [result]: The diff result to format
  /// 
  /// Returns a string containing the unified diff formatted output.
  /// 
  /// Example:
  /// ```dart
  /// final result = THDiffSuite.compareTexts(oldText, newText);
  /// final unifiedDiff = THDiffSuite.toUnifiedDiff(result);
  /// print(unifiedDiff);
  /// // Output:
  /// // --- file1	2023-01-01 12:00:00.000
  /// // +++ file2	2023-01-01 12:00:01.000
  /// // @@ -1,3 +1,3 @@
  /// //  line 1
  /// // -old line 2
  /// // +new line 2
  /// //  line 3
  /// ```
  static String toUnifiedDiff(THDiffResult result) {
    return UnifiedDiffFormatter.format(result);
  }
  
  /// Converts a diff result to TH MD diff format (custom format with annotations).
  /// 
  /// This method formats the diff result using a custom Markdown-friendly format
  /// that includes enhanced annotations and formatting suitable for documentation
  /// and presentation purposes.
  /// 
  /// Parameters:
  /// - [result]: The diff result to format
  /// 
  /// Returns a string containing the TH MD formatted diff output with enhanced
  /// readability and Markdown compatibility.
  /// 
  /// Example:
  /// ```dart
  /// final result = THDiffSuite.compareTexts(oldText, newText);
  /// final mdDiff = THDiffSuite.toMDDiff(result);
  /// print(mdDiff);
  /// // Output includes enhanced formatting and annotations
  /// ```
  static String toMDDiff(THDiffResult result) {
    return THMDDiffFormatter.format(result);
  }
  
  // Future methods - throw UnimplementedError for now
  
  /// Compares two TH MD Document objects (future implementation).
  /// 
  /// This method will provide structured document comparison capabilities
  /// beyond simple text comparison, understanding document structure and
  /// semantic differences.
  /// 
  /// Parameters:
  /// - [doc1]: The original document object
  /// - [doc2]: The modified document object  
  /// - [options]: Optional configuration for comparison behavior
  /// 
  /// Returns a [THDiffResult] with document-aware comparison results.
  /// 
  /// Throws [UnimplementedError] as this feature is not yet implemented.
  static Future<THDiffResult> compareDocuments(
    dynamic doc1, 
    dynamic doc2, [
    THDiffOptions? options,
  ]) async {
    throw UnimplementedError('Document comparison will be implemented in a future version');
  }
  
  /// Converts a diff result to context diff format (future implementation).
  /// 
  /// This method will format the diff result using the context diff format,
  /// which shows changes with surrounding context in a different layout
  /// than unified diff.
  /// 
  /// Parameters:
  /// - [result]: The diff result to format
  /// 
  /// Returns a string containing the context diff formatted output.
  /// 
  /// Throws [UnimplementedError] as this feature is not yet implemented.
  static String toContextDiff(THDiffResult result) {
    throw UnimplementedError('Context diff format will be implemented in a future version');
  }
  
  /// Compares directories recursively (future implementation).
  /// 
  /// This method will compare all files within two directories, providing
  /// a comprehensive comparison result for each file pair found.
  /// 
  /// Parameters:
  /// - [dirPath1]: Path to the original directory
  /// - [dirPath2]: Path to the modified directory
  /// - [options]: Optional configuration for comparison behavior
  /// 
  /// Returns a list of [THDiffResult] objects, one for each file comparison.
  /// 
  /// Throws [UnimplementedError] as this feature is not yet implemented.
  static Future<List<THDiffResult>> compareDirectories(
    String dirPath1,
    String dirPath2, [
    THDiffOptions? options,
  ]) async {
    throw UnimplementedError('Directory comparison will be implemented in a future version');
  }
  
  /// Compares binary files (future implementation).
  /// 
  /// This method will provide binary file comparison capabilities,
  /// detecting whether files are identical or different at the byte level.
  /// 
  /// Parameters:
  /// - [filePath1]: Path to the original binary file
  /// - [filePath2]: Path to the modified binary file
  /// - [options]: Optional configuration for comparison behavior
  /// 
  /// Returns a [THDiffResult] indicating whether the binary files differ.
  /// 
  /// Throws [UnimplementedError] as this feature is not yet implemented.
  static Future<THDiffResult> compareBinaryFiles(
    String filePath1,
    String filePath2, [
    THDiffOptions? options,
  ]) async {
    throw UnimplementedError('Binary file comparison will be implemented in a future version');
  }
}