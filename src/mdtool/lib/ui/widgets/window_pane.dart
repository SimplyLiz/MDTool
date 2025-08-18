import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_state.dart';
import 'window_header.dart';

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
  final bool showBorder;
  final EdgeInsets? padding;

  const WindowPane({
    super.key,
    required this.config,
    required this.child,
    this.showBorder = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: padding,
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            )
          : null,
      child: Column(
        children: [
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