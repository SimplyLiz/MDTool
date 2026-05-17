import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/core/services/frontmatter/frontmatter_manager.dart';
import 'package:mdtool/core/services/frontmatter/nyx_frontmatter.dart';
import 'package:path/path.dart' as p;

late Directory tmp;

void main() {
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mdtool-fm-');
  });
  tearDown(() async => await tmp.delete(recursive: true));

  test('reads existing nyx block from .md frontmatter', () async {
    final f = File(p.join(tmp.path, 'doc.md'));
    await f.writeAsString('''---
title: T
nyx:
  project: nyx.mdEdit
  persona: Aristaeus
---
body
''');
    final mgr = FrontmatterManager();
    final ctx = await mgr.load(f.path);
    expect(ctx.frontmatter.project, 'nyx.mdEdit');
    expect(ctx.frontmatter.persona, 'Aristaeus');
    expect(ctx.bodyOffset, greaterThan(0));   // byte offset where body begins
  });

  test('returns defaults when nyx block is missing', () async {
    final f = File(p.join(tmp.path, 'doc.md'));
    await f.writeAsString('---\ntitle: T\n---\nbody\n');
    final ctx = await FrontmatterManager().load(f.path);
    expect(ctx.frontmatter.project, isNull);
    expect(ctx.frontmatter.provider, NyxProvider.claude);
  });

  test('writes nyx block into existing frontmatter without clobbering other keys', () async {
    final f = File(p.join(tmp.path, 'doc.md'));
    await f.writeAsString('---\ntitle: T\n---\nbody\n');
    final mgr = FrontmatterManager();
    await mgr.save(f.path, const NyxFrontmatter(project: 'p', persona: 'P'));
    final content = await f.readAsString();
    expect(content, contains('title: T'));
    expect(content, contains('project: p'));
    expect(content.startsWith('---\n'), true);
    expect(content, contains('body'));
  });

  test('falls back to .nyx sidecar for non-md files', () async {
    final f = File(p.join(tmp.path, 'doc.txt'));
    await f.writeAsString('just text');
    final mgr = FrontmatterManager();
    await mgr.save(f.path, const NyxFrontmatter(project: 'sp'));
    expect(File(p.join(tmp.path, 'doc.txt.nyx')).existsSync(), true);
    final ctx = await mgr.load(f.path);
    expect(ctx.frontmatter.project, 'sp');
  });

  test('repairs broken nyx block by using defaults and emits diagnostic', () async {
    final f = File(p.join(tmp.path, 'doc.md'));
    await f.writeAsString('---\nnyx:\n  provider: bogus\n---\nbody\n');
    final ctx = await FrontmatterManager().load(f.path);
    expect(ctx.frontmatter.provider, NyxProvider.claude);
    expect(ctx.diagnostics, isNotEmpty);
  });
}
