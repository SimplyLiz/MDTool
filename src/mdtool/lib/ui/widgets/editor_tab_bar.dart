import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/tab_item.dart';
import '../../core/providers/app_state_provider.dart';

/// VS Code-style tab bar with drag-to-reorder support
class EditorTabBar extends ConsumerWidget {
  const EditorTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final tabs = appState.openTabs;

    if (tabs.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final elevation = Tween<double>(begin: 0, end: 6).evaluate(animation);
              return Material(
                elevation: elevation,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                child: child,
              );
            },
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) newIndex -= 1;
          ref.read(appStateProvider.notifier).reorderTabs(oldIndex, newIndex);
        },
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = tab.id == appState.activeTabId;
          return _TabChip(
            key: ValueKey(tab.id),
            tab: tab,
            index: index,
            isActive: isActive,
            isDark: isDark,
            colorScheme: colorScheme,
          );
        },
      ),
    );
  }
}

class _TabChip extends ConsumerWidget {
  final TabItem tab;
  final int index;
  final bool isActive;
  final bool isDark;
  final ColorScheme colorScheme;

  const _TabChip({
    super.key,
    required this.tab,
    required this.index,
    required this.isActive,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgColor = isActive
        ? (isDark ? colorScheme.surface : Colors.white)
        : Colors.transparent;
    final textColor = isActive
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final borderColor = isActive
        ? colorScheme.primary
        : Colors.transparent;

    return ReorderableDragStartListener(
      index: index,
      child: GestureDetector(
        onTap: () => ref.read(appStateProvider.notifier).switchToTab(tab.id),
        onDoubleTap: () {
          if (tab.isPreview) {
            ref.read(appStateProvider.notifier).pinTab(tab.id);
          }
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180, minWidth: 80),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: isActive ? 2 : 0,
              ),
              right: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // File icon
              Icon(
                Icons.description_outlined,
                size: 14,
                color: textColor,
              ),
              const SizedBox(width: 6),
              // File name (italic if preview tab)
              Flexible(
                child: Text(
                  tab.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: tab.isPreview ? FontStyle.italic : FontStyle.normal,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              // Dirty indicator or close button
              if (tab.isDirty)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary,
                  ),
                )
              else
                _TabCloseButton(
                  tabId: tab.id,
                  isActive: isActive,
                  textColor: textColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabCloseButton extends ConsumerStatefulWidget {
  final String tabId;
  final bool isActive;
  final Color textColor;

  const _TabCloseButton({
    required this.tabId,
    required this.isActive,
    required this.textColor,
  });

  @override
  ConsumerState<_TabCloseButton> createState() => _TabCloseButtonState();
}

class _TabCloseButtonState extends ConsumerState<_TabCloseButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => ref.read(appStateProvider.notifier).closeTab(widget.tabId, context),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _hovering || widget.isActive ? 1.0 : 0.0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _hovering
                  ? widget.textColor.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Icon(
              Icons.close,
              size: 12,
              color: widget.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
