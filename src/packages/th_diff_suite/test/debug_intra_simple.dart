import '../lib/src/intra_line_diff_algorithm.dart';
import '../lib/src/models/th_intra_line_diff.dart';

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
}