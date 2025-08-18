import 'package:flutter/widgets.dart';

enum MdBlockType {
  heading1('h1'),
  heading2('h2'), 
  heading3('h3'),
  heading4('h4'),
  heading5('h5'),
  heading6('h6'),
  paragraph('p'),
  code('code'),
  list('list'),
  image('img');
  
  const MdBlockType(this.value);
  final String value;
  
  static MdBlockType fromString(String type) {
    return MdBlockType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => MdBlockType.paragraph,
    );
  }
  
  bool get isHeading => this == heading1 || this == heading2 || this == heading3 || 
                       this == heading4 || this == heading5 || this == heading6;
  
  int? get headingLevel {
    switch (this) {
      case heading1: return 1;
      case heading2: return 2;
      case heading3: return 3;
      case heading4: return 4;
      case heading5: return 5;
      case heading6: return 6;
      default: return null;
    }
  }
}

class MdBlock {
  MdBlock({required this.type, required this.startLine, required this.endLine})
      : key = GlobalKey();
  
  final MdBlockType type;
  final int startLine;
  final int endLine; // inclusive
  final GlobalKey key;
  
  int get length => (endLine - startLine + 1).clamp(1, 1 << 30);
}

class BlockIndex {
  BlockIndex(this.blocks);
  final List<MdBlock> blocks;

  /// Find block containing a line (binary search).
  MdBlock? blockForLine(int line) {
    int lo = 0, hi = blocks.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final b = blocks[mid];
      if (line < b.startLine) {
        hi = mid - 1;
      } else if (line > b.endLine) {
        lo = mid + 1;
      } else {
        return b;
      }
    }
    // nearest previous block fallback
    return (hi >= 0 && hi < blocks.length) ? blocks[hi] : (blocks.isNotEmpty ? blocks.first : null);
  }
}

/// Very simple line-based parser; extend as needed.
BlockIndex buildBlockIndex(String source) {
  final lines = source.split('\n');
  final blocks = <MdBlock>[];

  bool inCode = false;
  int codeStart = 0;

  int start = 0;
  MdBlockType typeForParagraph = MdBlockType.paragraph;

  void flushParagraph(int end) {
    if (end >= start) {
      blocks.add(MdBlock(type: typeForParagraph, startLine: start, endLine: end));
    }
  }

  for (int i = 0; i < lines.length; i++) {
    final l = lines[i];

    // fenced code
    if (l.startsWith('```') || l.startsWith('~~~')) {
      if (!inCode) {
        // flush previous paragraph
        if (i - 1 >= start && start < i) flushParagraph(i - 1);
        inCode = true;
        codeStart = i;
      } else {
        inCode = false;
        blocks.add(MdBlock(type: MdBlockType.code, startLine: codeStart, endLine: i));
        start = i + 1;
      }
      continue;
    }
    if (inCode) continue;

    // headings
    final heading = RegExp(r'^(#{1,6})\s+').firstMatch(l);
    if (heading != null) {
      // flush previous paragraph
      if (i - 1 >= start && start < i) flushParagraph(i - 1);
      final level = heading.group(1)!.length;
      final headingType = switch (level) {
        1 => MdBlockType.heading1,
        2 => MdBlockType.heading2,
        3 => MdBlockType.heading3,
        4 => MdBlockType.heading4,
        5 => MdBlockType.heading5,
        6 => MdBlockType.heading6,
        _ => MdBlockType.heading1,
      };
      blocks.add(MdBlock(type: headingType, startLine: i, endLine: i));
      start = i + 1; // next paragraph starts after heading
      continue;
    }

    // lists
    if (RegExp(r'^\s*[-*+]\s+').hasMatch(l) || RegExp(r'^\s*\d+\.\s+').hasMatch(l)) {
      // flush previous paragraph
      if (i - 1 >= start && start < i) flushParagraph(i - 1);
      // aggregate contiguous list lines
      int j = i;
      while (j + 1 < lines.length &&
          (RegExp(r'^\s*[-*+]\s+').hasMatch(lines[j + 1]) ||
           RegExp(r'^\s*\d+\.\s+').hasMatch(lines[j + 1]) ||
           lines[j + 1].trim().isEmpty)) {
        j++;
      }
      blocks.add(MdBlock(type: MdBlockType.list, startLine: i, endLine: j));
      start = j + 1;
      i = j;
      continue;
    }

    // images (standalone)
    if (RegExp(r'!\[.*?\]\(.*?\)').hasMatch(l.trim())) {
      if (i - 1 >= start && start < i) flushParagraph(i - 1);
      blocks.add(MdBlock(type: MdBlockType.image, startLine: i, endLine: i));
      start = i + 1;
      continue;
    }

    // paragraphs handled by flush at boundaries
  }

  // tail paragraph
  if (!inCode && start <= lines.length - 1) {
    flushParagraph(lines.length - 1);
  }

  // ensure sorted
  blocks.sort((a, b) => a.startLine.compareTo(b.startLine));
  return BlockIndex(blocks);
}