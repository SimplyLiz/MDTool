import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_state.dart';
import '../../core/providers/app_state_provider.dart';
import 'window_header.dart';
import 'editor_tab_bar.dart';

enum WindowPaneType {
  editor,
  preview,
  secondaryEditor,
}

class WindowPaneConfig {
  final WindowPaneType type;
  final String? filePath;
  final String? content;
  final ActiveWindow activeWindow;
  final VoidCallback? onClose;
  final VoidCallback? onOpenFile;
  final VoidCallback? onNewFile;
  final VoidCallback? onSave;
  final VoidCallback? onChat;
  final VoidCallback? onTap;
  final bool isActive;
  final Widget? placeholder;

  const WindowPaneConfig({
    required this.type,
    required this.activeWindow,
    this.filePath,
    this.content,
    this.onClose,
    this.onOpenFile,
    this.onNewFile,
    this.onSave,
    this.onChat,
    this.onTap,
    this.isActive = false,
    this.placeholder,
  });
}

class WindowPane extends ConsumerWidget {
  final WindowPaneConfig config;
  final Widget child;
  final EdgeInsets? padding;

  const WindowPane({
    super.key,
    required this.config,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final showTabBar = config.type == WindowPaneType.editor &&
        config.activeWindow == ActiveWindow.primary &&
        appState.openTabs.isNotEmpty;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          children: [
            // Tab bar (only for primary editor pane when tabs are open)
            if (showTabBar) const EditorTabBar(),
            // Window header
            WindowHeader(
              windowType: _getWindowType(),
              activeWindowType: config.activeWindow,
              filePath: config.filePath,
              onOpenFile: config.onOpenFile,
              onNewFile: config.onNewFile,
              onChat: config.onChat,
              onSave: config.onSave,
              onClose: config.onClose,
              onTap: config.onTap,
            ),
            Container(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
            Expanded(
              child: GestureDetector(
                onTap: config.onTap,
                child: config.filePath != null || config.placeholder == null
                    ? child
                    : config.placeholder!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  WindowType _getWindowType() {
    switch (config.type) {
      case WindowPaneType.editor:
      case WindowPaneType.secondaryEditor:
        return WindowType.editor;
      case WindowPaneType.preview:
        return WindowType.preview;
    }
  }
}
