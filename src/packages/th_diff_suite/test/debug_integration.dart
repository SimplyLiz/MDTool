import '../lib/th_diff_suite.dart';

void main() {
  print('=== Integration Test Debug ===');
  
  // Test that should produce intra-line diffs
  const text1 = 'The quick brown fox';
  const text2 = 'The fast brown fox';
  
  final options = THDiffOptions(enableIntraLineDiff: true, wordLevelDiff: true);
  final result = THDiffSuite.compareTexts(text1, text2, options);
  
  print('Has changes: ${result.hasChanges}');
  print('Hunks: ${result.hunks.length}');
  
  for (int hunkIndex = 0; hunkIndex < result.hunks.length; hunkIndex++) {
    final hunk = result.hunks[hunkIndex];
    print('Hunk $hunkIndex with ${hunk.lines.length} lines:');
    for (int lineIndex = 0; lineIndex < hunk.lines.length; lineIndex++) {
      final line = hunk.lines[lineIndex];
      print('  Line $lineIndex: ${line.type.prefix}${line.content} (hasIntraDiff: ${line.hasIntraLineDiff})');
      if (line.hasIntraLineDiff) {
        print('    Intra-line diffs (${line.intraLineDiffs!.length}):');
        for (final intraDiff in line.intraLineDiffs!) {
          print('      ${intraDiff.type.displayName}: "${intraDiff.text}" (${intraDiff.startIndex}-${intraDiff.endIndex})');
        }
      }
    }
  }
  
  // Test with multiple lines
  print('\n=== Multi-line Test ===');
  const multiText1 = '''First line with original text
Second line with original content
Third line remains the same''';
        
  const multiText2 = '''First line with modified text  
Second line with updated content
Third line remains the same''';
  
  final multiResult = THDiffSuite.compareTexts(multiText1, multiText2, options);
  print('Multi-line has changes: ${multiResult.hasChanges}');
  print('Multi-line hunks: ${multiResult.hunks.length}');
  
  for (final hunk in multiResult.hunks) {
    print('Hunk with ${hunk.lines.length} lines:');
    for (final line in hunk.lines) {
      print('  ${line.type.prefix}${line.content} (hasIntraDiff: ${line.hasIntraLineDiff})');
    }
  }
}