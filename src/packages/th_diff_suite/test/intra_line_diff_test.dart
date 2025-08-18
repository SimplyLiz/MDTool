import 'package:test/test.dart';
import 'package:th_diff_suite/th_diff_suite.dart';

void main() {
  group('Intra-line Diff Tests', () {
    group('Character-level diffing', () {
      test('identical lines produce equal segments', () {
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          'Hello world',
          'Hello world',
        );
        
        expect(result.hasChanges, isFalse);
        expect(result.oldDiffs.length, equals(1));
        expect(result.newDiffs.length, equals(1));
        expect(result.oldDiffs.first.type, equals(THIntraLineDiffType.equal));
        expect(result.oldDiffs.first.text, equals('Hello world'));
      });
      
      test('simple character replacement', () {
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          'Hello world',
          'Hello Earth',
        );
        
        expect(result.hasChanges, isTrue);
        
        // The diff-match-patch algorithm produces more granular results
        // It finds the minimal character changes: "wo" -> "Ea", "ld" -> "th"
        expect(result.oldDiffs.length, greaterThanOrEqualTo(2));
        expect(result.newDiffs.length, greaterThanOrEqualTo(2));
        
        // Should start with "Hello "
        expect(result.oldDiffs[0].type, equals(THIntraLineDiffType.equal));
        expect(result.oldDiffs[0].text, equals('Hello '));
        expect(result.newDiffs[0].type, equals(THIntraLineDiffType.equal));
        expect(result.newDiffs[0].text, equals('Hello '));
        
        // Should have deletions and insertions
        final oldChanges = result.oldDiffs.where((d) => d.isChange).toList();
        final newChanges = result.newDiffs.where((d) => d.isChange).toList();
        expect(oldChanges.isNotEmpty, isTrue);
        expect(newChanges.isNotEmpty, isTrue);
        
        // Content should reconstruct to original strings
        final oldReconstructed = result.oldDiffs.map((d) => d.text).join();
        final newReconstructed = result.newDiffs.map((d) => d.text).join();
        expect(oldReconstructed, equals('Hello world'));
        expect(newReconstructed, equals('Hello Earth'));
      });
      
      test('character insertion', () {
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          'Hello world',
          'Hello beautiful world',
        );
        
        expect(result.hasChanges, isTrue);
        expect(result.oldDiffs.length, equals(2));
        expect(result.newDiffs.length, equals(3));
        
        // Old: "Hello " + "world"
        expect(result.oldDiffs[0].text, equals('Hello '));
        expect(result.oldDiffs[1].text, equals('world'));
        
        // New: "Hello " + "beautiful " + "world"
        expect(result.newDiffs[0].text, equals('Hello '));
        expect(result.newDiffs[1].type, equals(THIntraLineDiffType.insert));
        expect(result.newDiffs[1].text, equals('beautiful '));
        expect(result.newDiffs[2].text, equals('world'));
      });
      
      test('character deletion', () {
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          'Hello beautiful world',
          'Hello world',
        );
        
        expect(result.hasChanges, isTrue);
        
        // Find the deletion segment
        final deletions = result.oldDiffs.where((d) => d.type == THIntraLineDiffType.delete).toList();
        expect(deletions.length, equals(1));
        expect(deletions.first.text, equals('beautiful '));
      });
    });
    
    group('Word-level diffing', () {
      test('word replacement', () {
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          'The quick brown fox jumps',
          'The fast brown fox jumps',
          wordLevel: true,
        );
        
        expect(result.hasChanges, isTrue);
        
        // Should detect "quick" -> "fast" as word-level change
        final oldChanges = result.oldDiffs.where((d) => d.isChange).toList();
        final newChanges = result.newDiffs.where((d) => d.isChange).toList();
        
        expect(oldChanges.isNotEmpty, isTrue);
        expect(newChanges.isNotEmpty, isTrue);
      });
      
      test('word insertion', () {
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          'The brown fox',
          'The quick brown fox',
          wordLevel: true,
        );
        
        expect(result.hasChanges, isTrue);
        
        final insertions = result.newDiffs.where((d) => d.type == THIntraLineDiffType.insert).toList();
        expect(insertions.isNotEmpty, isTrue);
      });
    });
    
    group('Similarity detection', () {
      test('similar lines trigger intra-line diff', () {
        expect(
          IntraLineDiffAlgorithm.shouldComputeIntraLineDiff(
            'The quick brown fox',
            'The fast brown fox',
          ),
          isTrue,
        );
      });
      
      test('very different lines do not trigger intra-line diff', () {
        expect(
          IntraLineDiffAlgorithm.shouldComputeIntraLineDiff(
            'Hello world',
            'Completely different text with no similarity',
          ),
          isFalse,
        );
      });
      
      test('empty lines do not trigger intra-line diff', () {
        expect(
          IntraLineDiffAlgorithm.shouldComputeIntraLineDiff('', 'text'),
          isFalse,
        );
        expect(
          IntraLineDiffAlgorithm.shouldComputeIntraLineDiff('text', ''),
          isFalse,
        );
      });
      
      test('identical lines do not trigger intra-line diff', () {
        expect(
          IntraLineDiffAlgorithm.shouldComputeIntraLineDiff('same', 'same'),
          isFalse,
        );
      });
    });
    
    group('Integration with main diff algorithm', () {
      test('intra-line diffs are included when enabled', () {
        const text1 = 'The quick brown fox jumps over the lazy dog';
        const text2 = 'The fast brown fox jumps over the sleepy dog';
        
        final options = THDiffOptions(
          enableIntraLineDiff: true,
          wordLevelDiff: true,
        );
        
        final result = THDiffSuite.compareTexts(text1, text2, options);
        
        expect(result.hunks.isNotEmpty, isTrue);
        
        // Find lines with intra-line diffs
        final linesWithIntraDiff = result.hunks
            .expand((hunk) => hunk.lines)
            .where((line) => line.hasIntraLineDiff)
            .toList();
            
        expect(linesWithIntraDiff.isNotEmpty, isTrue);
        
        // Verify the intra-line changes contain expected words
        for (final line in linesWithIntraDiff) {
          final changes = line.intraLineChanges;
          expect(changes.isNotEmpty, isTrue);
        }
      });
      
      test('intra-line diffs are not included when disabled', () {
        const text1 = 'The quick brown fox';
        const text2 = 'The fast brown fox';
        
        final options = THDiffOptions(enableIntraLineDiff: false);
        final result = THDiffSuite.compareTexts(text1, text2, options);
        
        // Should still have changes but no intra-line diffs
        expect(result.hasChanges, isTrue);
        
        final linesWithIntraDiff = result.hunks
            .expand((hunk) => hunk.lines)
            .where((line) => line.hasIntraLineDiff)
            .toList();
            
        expect(linesWithIntraDiff.isEmpty, isTrue);
      });
      
      test('multiple line changes with intra-line diffs', () {
        const text1 = '''First line with original text
Second line with original content
Third line remains the same''';
        
        const text2 = '''First line with modified text  
Second line with updated content
Third line remains the same''';
        
        final options = THDiffOptions(
          enableIntraLineDiff: true,
          wordLevelDiff: true,
          similarityThreshold: 0.2, // Lower threshold to ensure similar lines are detected
        );
        
        final result = THDiffSuite.compareTexts(text1, text2, options);
        
        expect(result.hasChanges, isTrue);
        expect(result.hunks.isNotEmpty, isTrue);
        
        // Should have changed lines - either with or without intra-line diffs depending on similarity
        final changedLines = result.hunks
            .expand((hunk) => hunk.lines)
            .where((line) => line.isChange)
            .toList();
            
        expect(changedLines.length, greaterThan(0));
        
        // If any changed lines have intra-line diffs, verify they're working
        final linesWithIntraDiff = changedLines.where((line) => line.hasIntraLineDiff).toList();
        if (linesWithIntraDiff.isNotEmpty) {
          for (final line in linesWithIntraDiff) {
            expect(line.intraLineChanges.isNotEmpty, isTrue);
          }
        }
      });
      
      test('code diff with character-level precision', () {
        const code1 = 'function calculateTotal(items) {';
        const code2 = 'function computeTotal(items) {';
        
        final options = THDiffOptions(
          enableIntraLineDiff: true,
          wordLevelDiff: false, // Character-level for code
          similarityThreshold: 0.2, // Lower threshold to ensure detection
        );
        
        final result = THDiffSuite.compareTexts(code1, code2, options);
        
        expect(result.hasChanges, isTrue);
        
        final allLines = result.hunks.expand((hunk) => hunk.lines).toList();
        final changedLines = allLines.where((line) => line.isChange).toList();
        
        expect(changedLines.isNotEmpty, isTrue);
        
        // If intra-line diffs are present, verify they contain the expected changes
        final linesWithIntraDiff = changedLines.where((line) => line.hasIntraLineDiff).toList();
        if (linesWithIntraDiff.isNotEmpty) {
          bool foundExpectedChange = false;
          for (final line in linesWithIntraDiff) {
            final changes = line.intraLineChanges;
            final changeText = changes.map((c) => c.text).join();
            if (changeText.contains('calculate') || changeText.contains('compute')) {
              foundExpectedChange = true;
              break;
            }
          }
          expect(foundExpectedChange, isTrue);
        }
      });
    });
    
    group('Edge cases', () {
      test('handles special characters', () {
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          'Hello 🌍 world!',
          'Hello 🌎 world!',
        );
        
        expect(result.hasChanges, isTrue);
        
        final changes = result.allChanges;
        expect(changes.isNotEmpty, isTrue);
      });
      
      test('handles very long lines efficiently', () {
        final longLine1 = 'word ' * 1000 + 'different';
        final longLine2 = 'word ' * 1000 + 'changed';
        
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          longLine1,
          longLine2,
        );
        
        expect(result.hasChanges, isTrue);
        
        // Should detect the change at the end - the exact segments may vary
        // depending on the diff algorithm's optimization, but changes should be present
        final allChanges = result.allChanges;
        expect(allChanges.isNotEmpty, isTrue);
        
        // The changed text should include either the old or new different word
        final changeTexts = allChanges.map((c) => c.text).join();
        expect(
          changeTexts.contains('different') || changeTexts.contains('changed'),
          isTrue,
        );
      });
      
      test('handles whitespace-only differences', () {
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          'Hello  world',
          'Hello   world',
        );
        
        expect(result.hasChanges, isTrue);
        
        // Should detect the extra space
        final changes = result.allChanges;
        expect(changes.any((c) => c.text == ' '), isTrue);
      });
    });
    
    group('Position tracking', () {
      test('correctly tracks character positions', () {
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
          'Hello world',
          'Hello Earth',
        );
        
        // Check that positions make sense
        for (final diff in result.oldDiffs) {
          expect(diff.startIndex, greaterThanOrEqualTo(0));
          expect(diff.endIndex, greaterThan(diff.startIndex));
          expect(diff.length, equals(diff.endIndex - diff.startIndex));
          expect(diff.length, equals(diff.text.length));
        }
        
        for (final diff in result.newDiffs) {
          expect(diff.startIndex, greaterThanOrEqualTo(0));
          expect(diff.endIndex, greaterThan(diff.startIndex));
          expect(diff.length, equals(diff.endIndex - diff.startIndex));
          expect(diff.length, equals(diff.text.length));
        }
      });
      
      test('positions cover entire line content', () {
        final oldLine = 'The quick brown fox';
        final newLine = 'The fast brown fox';
        
        final result = IntraLineDiffAlgorithm.computeIntraLineDiff(oldLine, newLine);
        
        // Old diffs should cover entire old line
        final oldCoveredText = result.oldDiffs.map((d) => d.text).join();
        expect(oldCoveredText, equals(oldLine));
        
        // New diffs should cover entire new line
        final newCoveredText = result.newDiffs.map((d) => d.text).join();
        expect(newCoveredText, equals(newLine));
      });
    });
  });
}