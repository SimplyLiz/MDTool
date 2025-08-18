import '../lib/src/intra_line_diff_algorithm.dart';

void main() {
  print('=== Similarity Debug ===');
  
  // Test the similarity calculation directly
  final similarity = IntraLineDiffAlgorithm._computeSimilarity(
    'Hello world',
    'Completely different text with no similarity',
  );
  
  print('Similarity score: $similarity');
  
  final shouldTrigger = IntraLineDiffAlgorithm.shouldComputeIntraLineDiff(
    'Hello world',
    'Completely different text with no similarity',
  );
  
  print('Should trigger: $shouldTrigger');
  print('Default threshold: 0.3');
  print('Should trigger with threshold 0.3: ${similarity >= 0.3}');
}