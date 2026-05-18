import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/core/services/frontmatter/nyx_frontmatter.dart';

void main() {
  test('parses canonical map', () {
    final m = {
      'project': 'nyx.mdEdit',
      'persona': 'Aristaeus',
      'tone': 'technical-precise',
      'provider': 'claude',
      'memento': 'on',
      'axiom_lint': 'on',
      'private': false,
    };
    final f = NyxFrontmatter.fromMap(m);
    expect(f.project, 'nyx.mdEdit');
    expect(f.provider, NyxProvider.claude);
    expect(f.memento, NyxMemento.on);
    expect(f.private, false);
  });

  test('roundtrips through toMap', () {
    final f = NyxFrontmatter(project: 'p', persona: 'P', tone: 't', provider: NyxProvider.ollama);
    final m = f.toMap();
    final back = NyxFrontmatter.fromMap(m);
    expect(back.project, 'p');
    expect(back.provider, NyxProvider.ollama);
  });

  test('defaults sane fields', () {
    final f = NyxFrontmatter.fromMap({});
    expect(f.provider, NyxProvider.claude);
    expect(f.memento, NyxMemento.on);
    expect(f.axiomLint, NyxAxiomLint.on);
    expect(f.private, false);
  });
}
