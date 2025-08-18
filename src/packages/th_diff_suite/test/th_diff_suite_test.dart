import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:th_diff_suite/th_diff_suite.dart';

void main() {
  group('THDiffSuite Basic Tests', () {
    test('compareTexts - identical texts', () {
      const text1 = 'Hello World\nThis is line 2';
      const text2 = 'Hello World\nThis is line 2';
      
      final result = THDiffSuite.compareTexts(text1, text2);
      
      expect(result.hasChanges, isFalse);
      expect(result.stats.addedLines, equals(0));
      expect(result.stats.deletedLines, equals(0));
      expect(result.stats.changedLines, equals(0));
      expect(result.hunks, isEmpty);
    });

    test('compareTexts - simple addition', () {
      const text1 = 'Line 1\nLine 2';
      const text2 = 'Line 1\nLine 2\nLine 3';
      
      final result = THDiffSuite.compareTexts(text1, text2);
      
      expect(result.hasChanges, isTrue);
      expect(result.stats.addedLines, equals(1));
      expect(result.stats.deletedLines, equals(0));
      expect(result.stats.changedLines, equals(1));
      expect(result.hunks, isNotEmpty);
    });

    test('compareTexts - simple deletion', () {
      const text1 = 'Line 1\nLine 2\nLine 3';
      const text2 = 'Line 1\nLine 3';
      
      final result = THDiffSuite.compareTexts(text1, text2);
      
      expect(result.hasChanges, isTrue);
      expect(result.stats.addedLines, equals(0));
      expect(result.stats.deletedLines, equals(1));
      expect(result.stats.changedLines, equals(1));
    });

    test('compareTexts - modification', () {
      const text1 = 'Hello World';
      const text2 = 'Hello Universe';
      
      final result = THDiffSuite.compareTexts(text1, text2);
      
      expect(result.hasChanges, isTrue);
      expect(result.stats.addedLines, equals(1));
      expect(result.stats.deletedLines, equals(1));
      expect(result.stats.changedLines, equals(2));
    });
  });

  group('THDiffOptions Tests', () {
    test('default options', () {
      const options = THDiffOptions();
      
      expect(options.timeout, equals(1.0));
      expect(options.contextLines, equals(3));
      expect(options.enableSemanticCleanup, isTrue);
      expect(options.enableEfficiencyCleanup, isTrue);
      expect(options.ignoreWhitespace, isFalse);
      expect(options.ignoreCase, isFalse);
    });

    test('custom options', () {
      const options = THDiffOptions(
        timeout: 5.0,
        contextLines: 5,
        ignoreWhitespace: true,
        ignoreCase: true,
      );
      
      expect(options.timeout, equals(5.0));
      expect(options.contextLines, equals(5));
      expect(options.ignoreWhitespace, isTrue);
      expect(options.ignoreCase, isTrue);
    });

    test('copyWith method', () {
      const original = THDiffOptions(timeout: 1.0, contextLines: 3);
      final modified = original.copyWith(timeout: 2.0);
      
      expect(modified.timeout, equals(2.0));
      expect(modified.contextLines, equals(3)); // unchanged
    });
  });

  group('Output Format Tests', () {
    late THDiffResult testResult;

    setUp(() {
      const text1 = 'Hello World\nLine 2';
      const text2 = 'Hello Universe\nLine 2\nLine 3';
      testResult = THDiffSuite.compareTexts(text1, text2);
    });

    test('toGitDiff produces valid output', () {
      final gitDiff = THDiffSuite.toGitDiff(testResult);
      
      expect(gitDiff, contains('diff --git'));
      expect(gitDiff, contains('---'));
      expect(gitDiff, contains('+++'));
      expect(gitDiff, contains('@@'));
      expect(gitDiff, contains('-Hello World'));
      expect(gitDiff, contains('+Hello Universe'));
    });

    test('toUnifiedDiff produces valid output', () {
      final unifiedDiff = THDiffSuite.toUnifiedDiff(testResult);
      
      expect(unifiedDiff, contains('---'));
      expect(unifiedDiff, contains('+++'));
      expect(unifiedDiff, contains('@@'));
      expect(unifiedDiff, contains('-Hello World'));
      expect(unifiedDiff, contains('+Hello Universe'));
    });

    test('toMDDiff produces valid markdown', () {
      final mdDiff = THDiffSuite.toMDDiff(testResult);
      
      expect(mdDiff, contains('# TH MD Diff Report'));
      expect(mdDiff, contains('## Statistics'));
      expect(mdDiff, contains('**Added Lines**'));
      expect(mdDiff, contains('```diff'));
    });
  });

  group('THDiffStats Tests', () {
    test('calculateChangePercentage', () {
      const stats = THDiffStats(
        totalLines: 100,
        addedLines: 10,
        deletedLines: 5,
        unchangedLines: 85,
        hunksCount: 3,
      );
      
      expect(stats.changedLines, equals(15));
      expect(stats.changePercentage, equals(15.0));
    });

    test('zero division handling', () {
      const stats = THDiffStats(
        totalLines: 0,
        addedLines: 0,
        deletedLines: 0,
        unchangedLines: 0,
        hunksCount: 0,
      );
      
      expect(stats.changePercentage, equals(0.0));
    });
  });

  group('THDiffLine Tests', () {
    test('line type properties', () {
      const contextLine = THDiffLine(
        type: THDiffLineType.context,
        content: 'unchanged line',
        oldLineNumber: 1,
        newLineNumber: 1,
      );
      
      const addedLine = THDiffLine(
        type: THDiffLineType.addition,
        content: 'new line',
        oldLineNumber: null,
        newLineNumber: 2,
      );
      
      const deletedLine = THDiffLine(
        type: THDiffLineType.deletion,
        content: 'removed line',
        oldLineNumber: 2,
        newLineNumber: null,
      );
      
      expect(contextLine.isContext, isTrue);
      expect(contextLine.isChange, isFalse);
      
      expect(addedLine.isChange, isTrue);
      expect(addedLine.isContext, isFalse);
      
      expect(deletedLine.isChange, isTrue);
      expect(deletedLine.isContext, isFalse);
    });
  });

  group('Error Handling Tests', () {
    test('compareFiles - file not found', () async {
      expect(
        () => THDiffSuite.compareFiles('nonexistent1.txt', 'nonexistent2.txt'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('future methods throw UnimplementedError', () {
      expect(
        () => THDiffSuite.compareDocuments({}, {}),
        throwsUnimplementedError,
      );
      
      final result = THDiffSuite.compareTexts('a', 'b');
      expect(
        () => THDiffSuite.toContextDiff(result),
        throwsUnimplementedError,
      );
    });
  });
}
