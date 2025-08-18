import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

/// Model for breadcrumb items
class BreadcrumbItem {
  final String label;
  final String fullPath;

  const BreadcrumbItem(this.label, {required this.fullPath});

  @override
  bool operator ==(Object other) => identical(this, other) || other is BreadcrumbItem && runtimeType == other.runtimeType && label == other.label && fullPath == other.fullPath;

  @override
  int get hashCode => label.hashCode ^ fullPath.hashCode;
}

/// macOS-style breadcrumb navigation bar
class MacBreadcrumbBar extends StatelessWidget {
  /// Breadcrumb items from root to current
  final List<BreadcrumbItem> items;

  /// Called when a segment is tapped
  final void Function(int index, BreadcrumbItem item) onTap;

  /// Maximum visible segments before ellipsis
  final int? maxSegments;

  /// Optional leading icon (e.g., folder icon)
  final IconData? leadingIcon;

  /// Whether the current (last) segment is tappable
  final bool currentIsTappable;

  const MacBreadcrumbBar({super.key, required this.items, required this.onTap, this.maxSegments, this.leadingIcon, this.currentIsTappable = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Apply ellipsis if needed
    final visible = _applyEllipsis(items, maxSegments);
    final font = theme.textTheme.bodyMedium!.copyWith(
      height: 1.0, 
      letterSpacing: -0.1,
      fontSize: 13.0
    );

    final segments = <Widget>[];

    // Optional leading icon
    if (leadingIcon != null) {
      segments.add(Icon(leadingIcon, size: 14, color: isDark ? const Color(0xFFE5E5E5) : const Color(0xFF6B7280)));
      segments.add(const SizedBox(width: 6));
    }

    for (var i = 0; i < visible.length; i++) {
      final item = visible[i];
      final isLast = i == visible.length - 1;
      final tappable = isLast ? currentIsTappable : true;

      segments.add(_BreadcrumbSegment(label: item.label, tooltip: item.fullPath, isCurrent: isLast, isDark: isDark, font: font, enabled: tappable, onPrimaryTap: () => onTap(_mapIndex(items, visible, i), item), onSecondaryTap: () => _showPathMenu(context, item)));

      if (!isLast) {
        segments.add(const SizedBox(width: 6));
        segments.add(_Chevron(isDark: isDark));
        segments.add(const SizedBox(width: 6));
      }
    }

    return ScrollConfiguration(
      behavior: const _NoGlowBehavior(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        primary: false,
        child: Row(children: segments),
      ),
    );
  }

  static List<BreadcrumbItem> _applyEllipsis(List<BreadcrumbItem> input, int? maxSegments) {
    if (maxSegments == null || input.length <= maxSegments) return input;

    final keep = maxSegments.clamp(2, input.length);
    final head = input.first;
    final tail = input.sublist(input.length - (keep - 1));
    return [head, BreadcrumbItem('…', fullPath: input.map((e) => e.label).join('/')), ...tail.sublist(1)];
  }

  static int _mapIndex(List<BreadcrumbItem> full, List<BreadcrumbItem> visible, int visibleIndex) {
    final v = visible[visibleIndex];
    if (v.label != '…') {
      return full.indexWhere((e) => e.label == v.label && e.fullPath == v.fullPath);
    }
    final tailLen = visible.length - visibleIndex - 1;
    return full.length - 1 - tailLen;
  }

  static Future<void> _showPathMenu(BuildContext context, BreadcrumbItem item) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = overlay.localToGlobal(Offset.zero) & overlay.size;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.left + 12, pos.top + 28, pos.right, pos.bottom),
      items: [const PopupMenuItem(value: 'copy', child: Text('Copy Path'))],
    );

    if (selected == 'copy') {
      await Clipboard.setData(ClipboardData(text: item.fullPath));
    }
  }
}

/// Individual breadcrumb segment
class _BreadcrumbSegment extends StatefulWidget {
  final String label;
  final String tooltip;
  final bool isCurrent;
  final bool isDark;
  final TextStyle font;
  final bool enabled;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  const _BreadcrumbSegment({required this.label, required this.tooltip, required this.isCurrent, required this.isDark, required this.font, required this.enabled, required this.onPrimaryTap, required this.onSecondaryTap});

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    // Simple text styling without bubble background - matching macOS Finder
    final fg = widget.isDark ? const Color(0xFFE5E5E5) : const Color(0xFF1D1D1F);
    final hoverColor = widget.isDark ? const Color(0xFF007AFF) : const Color(0xFF007AFF);
    
    final segment = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.font.copyWith(
        color: widget.enabled ? (_hover ? hoverColor : fg) : fg.withOpacity(0.45), 
        fontWeight: FontWeight.w400,
        fontSize: 13.0
      ),
    );

    // Focus ring for accessibility - minimal like Finder
    final focusRing = _focused
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFF007AFF), width: 1),
            ),
          )
        : const SizedBox.shrink();

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(), SingleActivator(LogicalKeyboardKey.space): ActivateIntent()},
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPrimaryTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onPrimaryTap : null,
          onSecondaryTap: widget.onSecondaryTap,
          child: Tooltip(
            message: widget.tooltip,
            waitDuration: const Duration(milliseconds: 400),
            child: Stack(alignment: Alignment.center, children: [focusRing, segment]),
          ),
        ),
      ),
    );
  }
}

/// Chevron separator between segments
class _Chevron extends StatelessWidget {
  final bool isDark;
  const _Chevron({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Icon(
      CupertinoIcons.chevron_right, 
      size: 13.0, 
      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93)
    );
  }
}

/// Custom scroll behavior without glow effects
class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
