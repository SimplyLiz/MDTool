import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/preferences_provider.dart';
import 'markdown_editor.dart';
import 'markdown_preview.dart';

class EditorView extends ConsumerStatefulWidget {
  const EditorView({super.key});

  @override
  ConsumerState<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends ConsumerState<EditorView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showEditor = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final preferencesAsync = ref.watch(preferencesProvider);

    // Trigger animation when mode changes
    if (_showEditor != appState.isEditMode) {
      _showEditor = appState.isEditMode;
      _animationController.reset();
      _animationController.forward();
    }
    
    return preferencesAsync.when(
      data: (preferences) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: IndexedStack(
                index: appState.isEditMode ? 0 : 1,
                children: const [
                  MarkdownEditor(),
                  MarkdownPreview(),
                ],
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading preferences: $error'),
      ),
    );
  }

}