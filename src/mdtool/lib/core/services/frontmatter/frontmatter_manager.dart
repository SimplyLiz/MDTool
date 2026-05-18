import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'nyx_frontmatter.dart';
import 'nyx_schema.dart';

class DocContext {
  final NyxFrontmatter frontmatter;
  /// Byte offset in the original file where the body content starts (0 if no frontmatter).
  final int bodyOffset;
  final List<String> diagnostics;
  const DocContext({required this.frontmatter, required this.bodyOffset, required this.diagnostics});
}

class FrontmatterManager {
  /// Reads `nyx:` block from a doc. Tries inline YAML frontmatter first; falls back
  /// to `<path>.nyx` sidecar for non-MD files.
  Future<DocContext> load(String path) async {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.md' || ext == '.markdown') {
      final content = await File(path).readAsString();
      return _loadFromMd(content);
    }
    return _loadFromSidecar(path);
  }

  /// Writes `nyx:` block to a doc. For non-MD files, writes a `<path>.nyx` sidecar.
  Future<void> save(String path, NyxFrontmatter fm) async {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.md' || ext == '.markdown') {
      await _saveToMd(path, fm);
    } else {
      await _saveSidecar(path, fm);
    }
  }

  DocContext _loadFromMd(String content) {
    final diagnostics = <String>[];
    if (!content.startsWith('---')) {
      return DocContext(frontmatter: const NyxFrontmatter(), bodyOffset: 0, diagnostics: diagnostics);
    }
    final endIdx = content.indexOf('\n---', 4);
    if (endIdx < 0) {
      diagnostics.add('Unclosed frontmatter');
      return DocContext(frontmatter: const NyxFrontmatter(), bodyOffset: 0, diagnostics: diagnostics);
    }
    final yamlStr = content.substring(4, endIdx);
    final yaml = loadYaml(yamlStr) as Map?;
    final nyxBlock = yaml?['nyx'] as Map?;
    NyxFrontmatter fm;
    if (nyxBlock == null) {
      fm = const NyxFrontmatter();
    } else {
      final r = validateNyxBlock(nyxBlock);
      if (!r.isValid) diagnostics.addAll(r.errors);
      fm = NyxFrontmatter.fromMap(nyxBlock);
    }
    return DocContext(frontmatter: fm, bodyOffset: endIdx + 5, diagnostics: diagnostics);
  }

  Future<void> _saveToMd(String path, NyxFrontmatter fm) async {
    final file = File(path);
    final original = await file.readAsString();
    final blockText = _renderNyxBlockYaml(fm);

    String newContent;
    if (original.startsWith('---')) {
      final endIdx = original.indexOf('\n---', 4);
      if (endIdx < 0) throw FormatException('Unclosed frontmatter in $path');
      final yamlStr = original.substring(4, endIdx);
      final yaml = loadYaml(yamlStr) as Map? ?? {};
      // Preserve non-nyx keys; replace nyx block.
      final preserved = <String, Object?>{};
      yaml.forEach((k, v) {
        if (k != 'nyx') preserved[k.toString()] = v;
      });
      final rebuilt = StringBuffer('---\n');
      preserved.forEach((k, v) => rebuilt.write(_renderYamlEntry(k, v, indent: '')));
      rebuilt.write(blockText);
      rebuilt.write('---\n');
      rebuilt.write(original.substring(endIdx + 5));
      newContent = rebuilt.toString();
    } else {
      newContent = '---\n$blockText---\n$original';
    }
    await file.writeAsString(newContent);
  }

  Future<DocContext> _loadFromSidecar(String path) async {
    final sidecar = File('$path.nyx');
    if (!sidecar.existsSync()) {
      return const DocContext(frontmatter: NyxFrontmatter(), bodyOffset: 0, diagnostics: []);
    }
    final yaml = loadYaml(await sidecar.readAsString()) as Map?;
    final nyxBlock = yaml?['nyx'] as Map?;
    if (nyxBlock == null) return const DocContext(frontmatter: NyxFrontmatter(), bodyOffset: 0, diagnostics: []);
    final r = validateNyxBlock(nyxBlock);
    return DocContext(
      frontmatter: NyxFrontmatter.fromMap(nyxBlock),
      bodyOffset: 0,
      diagnostics: r.isValid ? const [] : r.errors,
    );
  }

  Future<void> _saveSidecar(String path, NyxFrontmatter fm) async {
    await File('$path.nyx').writeAsString(_renderNyxBlockYaml(fm));
  }

  String _renderNyxBlockYaml(NyxFrontmatter fm) {
    final m = fm.toMap();
    final sb = StringBuffer('nyx:\n');
    m.forEach((k, v) => sb.write(_renderYamlEntry(k, v, indent: '  ')));
    return sb.toString();
  }

  /// Renders a single `key: value` entry with appropriate indent. If value is a
  /// Map, emits a nested block. Maps with empty contents emit `key: {}` inline.
  String _renderYamlEntry(String key, Object? value, {required String indent}) {
    if (value is Map) {
      final cast = value.cast<Object?, Object?>();
      if (cast.isEmpty) return '$indent$key: {}\n';
      final sb = StringBuffer('$indent$key:\n');
      cast.forEach((kk, vv) {
        sb.write(_renderYamlEntry(kk.toString(), vv, indent: '$indent  '));
      });
      return sb.toString();
    }
    return '$indent$key: ${_yamlInline(value)}\n';
  }

  String _yamlInline(Object? v) {
    if (v == null) return 'null';
    if (v is bool || v is num) return v.toString();
    if (v is String) {
      // Quote if it contains a colon, leading whitespace, or empty.
      if (v.isEmpty || v.contains(':') || v.trimLeft() != v) {
        return '"${v.replaceAll('"', r'\"')}"';
      }
      return v;
    }
    return '"${v.toString().replaceAll('"', r'\"')}"';
  }
}
