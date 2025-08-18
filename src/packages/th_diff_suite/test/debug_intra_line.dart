import 'package:th_diff_suite/th_diff_suite.dart';

void main() {
  print('=== Debug intra-line diffing ===');
  
  // Test simple character replacement
  final result = IntraLineDiffAlgorithm.computeIntraLineDiff(
    'Hello world',
    'Hello Earth',
  );
  
  print('Has changes: ${result.hasChanges}');
  print('Old diffs (${result.oldDiffs.length}):');
  for (int i = 0; i < result.oldDiffs.length; i++) {
    final diff = result.oldDiffs[i];
    print('  $i: ${diff.type.displayName} "${diff.text}" (${diff.startIndex}-${diff.endIndex})');
  }
  
  print('New diffs (${result.newDiffs.length}):');
  for (int i = 0; i < result.newDiffs.length; i++) {
    final diff = result.newDiffs[i];
    print('  $i: ${diff.type.displayName} "${diff.text}" (${diff.startIndex}-${diff.endIndex})');
  }
  
  // Test similarity detection
  print('\n=== Similarity Detection ===');
  final shouldTrigger1 = IntraLineDiffAlgorithm.shouldComputeIntraLineDiff(
    'Hello world',
    'Completely different text with no similarity',
  );
  print('Should trigger diff for very different lines: $shouldTrigger1');
  
  // Test integration
  print('\n=== Integration Test ===');
  const text1 = 'The quick brown fox';
  const text2 = 'The fast brown fox';
  
  final options = THDiffOptions(enableIntraLineDiff: true);
  final diffResult = THDiffSuite.compareTexts(text1, text2, options);
  
  print('Has changes: ${diffResult.hasChanges}');
  print('Hunks: ${diffResult.hunks.length}');
  
  for (final hunk in diffResult.hunks) {
    print('Hunk with ${hunk.lines.length} lines:');
    for (final line in hunk.lines) {
      print('  ${line.type.prefix}${line.content} (hasIntraDiff: ${line.hasIntraLineDiff})');
      if (line.hasIntraLineDiff) {
        print('    Intra-line changes:');
        for (final intraDiff in line.intraLineDiffs!) {
          print('      ${intraDiff.type.displayName}: "${intraDiff.text}"');
        }
      }
    }
  }
}