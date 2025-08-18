import 'models/th_diff_line.dart';
import 'models/th_diff_options.dart';
import 'intra_line_diff_algorithm.dart';

/// Enhanced line-based diff algorithm with intra-line support
class LineDiffAlgorithm {
  /// Compare two lists of lines and return diff lines with optional intra-line diffing
  /// 
  /// [lines1] Original lines
  /// [lines2] Modified lines  
  /// [options] Optional configuration for diff behavior
  static List<THDiffLine> diffLines(
    List<String> lines1, 
    List<String> lines2, {
    THDiffOptions? options,
  }) {
    final result = <THDiffLine>[];
    
    // Handle empty cases
    if (lines1.isEmpty && lines2.isEmpty) {
      return result;
    }
    
    if (lines1.isEmpty) {
      // All lines in lines2 are additions
      for (int i = 0; i < lines2.length; i++) {
        result.add(THDiffLine(
          type: THDiffLineType.addition,
          content: lines2[i],
          oldLineNumber: null,
          newLineNumber: i + 1,
        ));
      }
      return result;
    }
    
    if (lines2.isEmpty) {
      // All lines in lines1 are deletions
      for (int i = 0; i < lines1.length; i++) {
        result.add(THDiffLine(
          type: THDiffLineType.deletion,
          content: lines1[i],
          oldLineNumber: i + 1,
          newLineNumber: null,
        ));
      }
      return result;
    }
    
    // Use simple two-pointer approach for now
    int i = 0, j = 0;
    int oldLineNum = 1, newLineNum = 1;
    
    while (i < lines1.length && j < lines2.length) {
      if (lines1[i] == lines2[j]) {
        // Lines match - context
        result.add(THDiffLine(
          type: THDiffLineType.context,
          content: lines1[i],
          oldLineNumber: oldLineNum,
          newLineNumber: newLineNum,
        ));
        i++;
        j++;
        oldLineNum++;
        newLineNum++;
      } else {
        // Lines differ - find the next common line
        final nextCommon = _findNextCommonLine(lines1, lines2, i, j);
        
        if (nextCommon != null) {
          final nextI = nextCommon[0];
          final nextJ = nextCommon[1];
          
          // Add deletions
          while (i < nextI) {
            result.add(THDiffLine(
              type: THDiffLineType.deletion,
              content: lines1[i],
              oldLineNumber: oldLineNum,
              newLineNumber: null,
            ));
            i++;
            oldLineNum++;
          }
          
          // Add additions
          while (j < nextJ) {
            result.add(THDiffLine(
              type: THDiffLineType.addition,
              content: lines2[j],
              oldLineNumber: null,
              newLineNumber: newLineNum,
            ));
            j++;
            newLineNum++;
          }
        } else {
          // No more common lines - check if lines are similar for intra-line diff
          final oldLine = lines1[i];
          final newLine = lines2[j];
          
          if (options?.enableIntraLineDiff == true && 
              IntraLineDiffAlgorithm.shouldComputeIntraLineDiff(
                oldLine, 
                newLine, 
                similarityThreshold: options?.similarityThreshold ?? 0.3,
              )) {
            // Lines are similar - create modified lines with intra-line diffs
            final intraResult = IntraLineDiffAlgorithm.computeIntraLineDiff(
              oldLine, 
              newLine,
              wordLevel: options?.wordLevelDiff ?? false,
            );
            
            result.add(THDiffLine(
              type: THDiffLineType.deletion,
              content: oldLine,
              oldLineNumber: oldLineNum,
              newLineNumber: null,
              intraLineDiffs: intraResult.oldDiffs,
            ));
            result.add(THDiffLine(
              type: THDiffLineType.addition,
              content: newLine,
              oldLineNumber: null,
              newLineNumber: newLineNum,
              intraLineDiffs: intraResult.newDiffs,
            ));
          } else {
            // Lines are different - treat as separate deletion and addition
            result.add(THDiffLine(
              type: THDiffLineType.deletion,
              content: oldLine,
              oldLineNumber: oldLineNum,
              newLineNumber: null,
            ));
            result.add(THDiffLine(
              type: THDiffLineType.addition,
              content: newLine,
              oldLineNumber: null,
              newLineNumber: newLineNum,
            ));
          }
          
          i++;
          j++;
          oldLineNum++;
          newLineNum++;
        }
      }
    }
    
    // Add remaining deletions
    while (i < lines1.length) {
      result.add(THDiffLine(
        type: THDiffLineType.deletion,
        content: lines1[i],
        oldLineNumber: oldLineNum,
        newLineNumber: null,
      ));
      i++;
      oldLineNum++;
    }
    
    // Add remaining additions
    while (j < lines2.length) {
      result.add(THDiffLine(
        type: THDiffLineType.addition,
        content: lines2[j],
        oldLineNumber: null,
        newLineNumber: newLineNum,
      ));
      j++;
      newLineNum++;
    }
    
    return result;
  }
  
  /// Find the next common line between two lists
  static List<int>? _findNextCommonLine(List<String> lines1, List<String> lines2, int startI, int startJ) {
    // Look ahead for the next matching line within a reasonable distance
    const maxLookAhead = 10;
    
    for (int distance = 1; distance <= maxLookAhead; distance++) {
      // Check if line at startI+distance matches any line in lines2[startJ..startJ+distance]
      if (startI + distance < lines1.length) {
        for (int j = startJ; j <= startJ + distance && j < lines2.length; j++) {
          if (lines1[startI + distance] == lines2[j]) {
            return [startI + distance, j];
          }
        }
      }
      
      // Check if line at startJ+distance matches any line in lines1[startI..startI+distance]
      if (startJ + distance < lines2.length) {
        for (int i = startI; i <= startI + distance && i < lines1.length; i++) {
          if (lines2[startJ + distance] == lines1[i]) {
            return [i, startJ + distance];
          }
        }
      }
    }
    
    return null;
  }
}