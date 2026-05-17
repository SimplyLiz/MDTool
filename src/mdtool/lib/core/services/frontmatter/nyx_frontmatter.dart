enum NyxProvider { claude, openai, ollama }
enum NyxMemento { on, off, bulk }
enum NyxAxiomLint { on, off, panelOnly }

class NyxFrontmatter {
  final String? project;
  final String? persona;
  final String? tone;
  final NyxProvider provider;
  final NyxMemento memento;
  final NyxAxiomLint axiomLint;
  final bool private;
  final Map<String, Object?> sources; // free-form per-source overrides (validated separately)

  const NyxFrontmatter({
    this.project,
    this.persona,
    this.tone,
    this.provider = NyxProvider.claude,
    this.memento = NyxMemento.on,
    this.axiomLint = NyxAxiomLint.on,
    this.private = false,
    this.sources = const {},
  });

  factory NyxFrontmatter.fromMap(Map<dynamic, dynamic> m) {
    return NyxFrontmatter(
      project: m['project'] as String?,
      persona: m['persona'] as String?,
      tone: m['tone'] as String?,
      provider: _parseProvider(m['provider']),
      memento: _parseMemento(m['memento']),
      axiomLint: _parseAxiomLint(m['axiom_lint']),
      private: (m['private'] as bool?) ?? false,
      sources: ((m['sources'] as Map?) ?? const {}).cast<String, Object?>(),
    );
  }

  Map<String, Object?> toMap() => {
        if (project != null) 'project': project,
        if (persona != null) 'persona': persona,
        if (tone != null) 'tone': tone,
        'provider': provider.name,
        'memento': memento.name,
        'axiom_lint': axiomLint == NyxAxiomLint.panelOnly ? 'panel-only' : axiomLint.name,
        'private': private,
        if (sources.isNotEmpty) 'sources': sources,
      };

  static NyxProvider _parseProvider(Object? v) =>
      NyxProvider.values.firstWhere((e) => e.name == v, orElse: () => NyxProvider.claude);
  static NyxMemento _parseMemento(Object? v) =>
      NyxMemento.values.firstWhere((e) => e.name == v, orElse: () => NyxMemento.on);
  static NyxAxiomLint _parseAxiomLint(Object? v) {
    if (v == 'panel-only') return NyxAxiomLint.panelOnly;
    return NyxAxiomLint.values.firstWhere((e) => e.name == v, orElse: () => NyxAxiomLint.on);
  }
}
