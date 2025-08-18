import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:th_diff_suite/th_diff_suite.dart';

void main() {
  group('Reference Comparison Tests', () {
    late String document1;
    late String document2;
    late String referenceUnifiedDiff;
    late String referenceGitDiff;

    setUpAll(() async {
      // Load test documents
      final file1 = File('test/data/document_v1.md');
      final file2 = File('test/data/document_v2.md');
      
      document1 = await file1.readAsString();
      document2 = await file2.readAsString();
      
      // Load reference diffs
      final refUnified = File('test/data/reference_unified.diff');
      final refGit = File('test/data/reference_git.diff');
      
      referenceUnifiedDiff = await refUnified.readAsString();
      referenceGitDiff = await refGit.readAsString();
    });

    test('file comparison matches CLI unified diff structure', () async {
      final result = await THDiffSuite.compareFiles(
        'test/data/document_v1.md',
        'test/data/document_v2.md',
      );
      
      expect(result.hasChanges, isTrue);
      
      // Check statistics are reasonable
      expect(result.stats.addedLines, greaterThan(0));
      expect(result.stats.deletedLines, greaterThan(0));
      expect(result.stats.hunksCount, greaterThan(0));
      
      final ourUnifiedDiff = THDiffSuite.toUnifiedDiff(result);
      
      // Check basic structure
      expect(ourUnifiedDiff, contains('---'));
      expect(ourUnifiedDiff, contains('+++'));
      expect(ourUnifiedDiff, contains('@@'));
      
      // Check some key changes are present
      expect(ourUnifiedDiff, contains('-This is the initial version'));
      expect(ourUnifiedDiff, contains('+This is the updated version'));
      expect(ourUnifiedDiff, contains('Feature D: New analytics'));
    });

    test('git diff format matches CLI git diff structure', () async {
      final result = await THDiffSuite.compareFiles(
        'test/data/document_v1.md',
        'test/data/document_v2.md',
      );
      
      final ourGitDiff = THDiffSuite.toGitDiff(result);
      
      // Check Git diff headers
      expect(ourGitDiff, contains('diff --git'));
      expect(ourGitDiff, contains('index'));
      expect(ourGitDiff, contains('--- a/'));
      expect(ourGitDiff, contains('+++ b/'));
      expect(ourGitDiff, contains('@@'));
      
      // Check some key changes
      expect(ourGitDiff, contains('-This is the initial version'));
      expect(ourGitDiff, contains('+This is the updated version'));
    });

    test('text comparison produces correct statistics', () {
      final result = THDiffSuite.compareTexts(document1, document2);
      
      // Verify we have changes
      expect(result.hasChanges, isTrue);
      expect(result.stats.changedLines, greaterThan(0));
      expect(result.stats.changePercentage, greaterThan(0.0));
      
      // Check that we have both additions and deletions
      expect(result.stats.addedLines, greaterThan(0));
      expect(result.stats.deletedLines, greaterThan(0));
      
      // Verify hunks exist
      expect(result.hunks, isNotEmpty);
      expect(result.hunks.every((h) => h.hasChanges), isTrue);
    });

    test('MD format contains rich information', () async {
      final result = await THDiffSuite.compareFiles(
        'test/data/document_v1.md', 
        'test/data/document_v2.md',
      );
      
      final mdDiff = THDiffSuite.toMDDiff(result);
      
      // Check MD format structure
      expect(mdDiff, contains('# TH MD Diff Report'));
      expect(mdDiff, contains('## Statistics'));
      expect(mdDiff, contains('## Changes Overview'));
      expect(mdDiff, contains('## Detailed Changes'));
      expect(mdDiff, contains('```diff'));
      
      // Check statistics are included
      expect(mdDiff, contains('**Added Lines**'));
      expect(mdDiff, contains('**Deleted Lines**'));
      expect(mdDiff, contains('**Change Percentage**'));
      
      // Check file information
      expect(mdDiff, contains('document_v1.md'));
      expect(mdDiff, contains('document_v2.md'));
    });

    test('line-by-line diff accuracy', () {
      // Test with simple known changes
      const text1 = '''Line 1
Line 2
Line 3''';
      
      const text2 = '''Line 1
Modified Line 2
Line 3
Line 4''';
      
      final result = THDiffSuite.compareTexts(text1, text2);
      
      expect(result.hasChanges, isTrue);
      expect(result.stats.addedLines, equals(2)); // "Modified Line 2" and "Line 4"
      expect(result.stats.deletedLines, equals(1)); // "Line 2"
      
      final changedLines = result.allChangedLines;
      expect(changedLines.length, equals(3));
      
      // Find the specific changes
      final deletedLines = changedLines.where((l) => l.type == THDiffLineType.deletion);
      final addedLines = changedLines.where((l) => l.type == THDiffLineType.addition);
      
      expect(deletedLines.any((l) => l.content == 'Line 2'), isTrue);
      expect(addedLines.any((l) => l.content == 'Modified Line 2'), isTrue);
      expect(addedLines.any((l) => l.content == 'Line 4'), isTrue);
    });

    test('empty and identical files handling', () {
      // Test identical files
      final result1 = THDiffSuite.compareTexts('same', 'same');
      expect(result1.hasChanges, isFalse);
      expect(result1.stats.changedLines, equals(0));
      
      // Test empty files
      final result2 = THDiffSuite.compareTexts('', '');
      expect(result2.hasChanges, isFalse);
      
      // Test empty vs content
      final result3 = THDiffSuite.compareTexts('', 'content');
      expect(result3.hasChanges, isTrue);
      expect(result3.stats.addedLines, equals(1));
      expect(result3.stats.deletedLines, equals(0));
    });

    test('hunk boundaries are correct', () {
      final result = THDiffSuite.compareTexts(document1, document2);
      
      for (final hunk in result.hunks) {
        // Verify hunk ranges make sense
        expect(hunk.oldStart, greaterThan(0));
        expect(hunk.newStart, greaterThan(0));
        expect(hunk.oldCount, greaterThan(0));
        expect(hunk.newCount, greaterThan(0));
        
        // Verify lines in hunk match the counts
        final contextAndDeleted = hunk.lines.where((l) => 
            l.type == THDiffLineType.context || l.type == THDiffLineType.deletion).length;
        final contextAndAdded = hunk.lines.where((l) => 
            l.type == THDiffLineType.context || l.type == THDiffLineType.addition).length;
            
        expect(contextAndDeleted, equals(hunk.oldCount));
        expect(contextAndAdded, equals(hunk.newCount));
      }
    });

    test('options affect diff output', () {
      // Test with different context lines
      final options1 = THDiffOptions(contextLines: 1);
      final options3 = THDiffOptions(contextLines: 3);
      
      final result1 = THDiffSuite.compareTexts(document1, document2, options1);
      final result3 = THDiffSuite.compareTexts(document1, document2, options3);
      
      // With more context lines, we might have fewer hunks (merged) or longer hunks
      expect(result1.hunks.isNotEmpty, isTrue);
      expect(result3.hunks.isNotEmpty, isTrue);
      
      // Test cleanup options
      final optionsNoCleanup = THDiffOptions(
        enableSemanticCleanup: false,
        enableEfficiencyCleanup: false,
      );
      
      final resultNoCleanup = THDiffSuite.compareTexts(document1, document2, optionsNoCleanup);
      expect(resultNoCleanup.hasChanges, isTrue);
    });
  });

  group('Edge Cases and Performance', () {
    test('handles large text efficiently', () {
      // Create moderately large text
      final largeText1 = List.generate(1000, (i) => 'Line $i content here').join('\n');
      final largeText2 = List.generate(1000, (i) => 
          i == 500 ? 'Modified Line $i content here' : 'Line $i content here').join('\n');
      
      final stopwatch = Stopwatch()..start();
      final result = THDiffSuite.compareTexts(largeText1, largeText2);
      stopwatch.stop();
      
      expect(result.hasChanges, isTrue);
      expect(result.stats.changedLines, equals(2)); // 1 deletion + 1 addition
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should be fast
    });

    test('handles special characters and unicode', () {
      const text1 = '''Hello 世界
Emoji: 😀 🚀 ✨
Special chars: \n\t\r"'\\''';
      
      const text2 = '''Hello 世界!
Emoji: 😀 🚀 ✨ 🎉
Special chars: \n\t\r"'\\ updated''';
      
      final result = THDiffSuite.compareTexts(text1, text2);
      
      expect(result.hasChanges, isTrue);
      final diff = THDiffSuite.toUnifiedDiff(result);
      expect(diff, contains('世界'));
      expect(diff, contains('😀'));
    });

    test('handles very different files', () {
      const text1 = 'Completely different content A';
      const text2 = 'Totally unrelated content B with more stuff';
      
      final result = THDiffSuite.compareTexts(text1, text2);
      
      expect(result.hasChanges, isTrue);
      expect(result.stats.changePercentage, greaterThan(50.0)); // Very different
    });

    test('multiline string handling', () {
      const text1 = '''First line
Second line
Third line''';
      
      const text2 = '''First line
Second line modified
Third line
Fourth line''';
      
      final result = THDiffSuite.compareTexts(text1, text2);
      final gitDiff = THDiffSuite.toGitDiff(result);
      
      // Should properly handle line breaks
      expect(gitDiff.split('\n').length, greaterThan(5));
      expect(gitDiff, contains('-Second line'));
      expect(gitDiff, contains('+Second line modified'));
      expect(gitDiff, contains('+Fourth line'));
    });
  });
}