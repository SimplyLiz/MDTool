import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FindDialog extends ConsumerStatefulWidget {
  final String initialText;
  final Function(String query, bool matchCase, bool wholeWord) onSearch;
  final VoidCallback onClose;
  final Function(bool forward) onNavigate;

  const FindDialog({
    super.key,
    required this.initialText,
    required this.onSearch,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  ConsumerState<FindDialog> createState() => _FindDialogState();
}

class _FindDialogState extends ConsumerState<FindDialog> {
  late TextEditingController _searchController;
  bool _matchCase = false;
  bool _wholeWord = false;
  int _currentMatch = 0;
  int _totalMatches = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialText);
    _searchController.addListener(_onSearchChanged);
    
    // Auto-focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    widget.onSearch(_searchController.text, _matchCase, _wholeWord);
  }

  void _toggleMatchCase() {
    setState(() {
      _matchCase = !_matchCase;
    });
    _onSearchChanged();
  }

  void _toggleWholeWord() {
    setState(() {
      _wholeWord = !_wholeWord;
    });
    _onSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search input field
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Find...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              onSubmitted: (_) => widget.onNavigate(true),
            ),
          ),
          const SizedBox(width: 8),

          // Match counter
          if (_searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$_currentMatch/$_totalMatches',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(width: 8),

          // Navigation buttons
          IconButton(
            onPressed: _searchController.text.isNotEmpty 
                ? () => widget.onNavigate(false) 
                : null,
            icon: const Icon(Icons.keyboard_arrow_up),
            iconSize: 18,
            tooltip: 'Previous (Shift+Enter)',
          ),
          IconButton(
            onPressed: _searchController.text.isNotEmpty 
                ? () => widget.onNavigate(true) 
                : null,
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 18,
            tooltip: 'Next (Enter)',
          ),

          // Options
          IconButton(
            onPressed: _toggleMatchCase,
            icon: Icon(
              Icons.text_fields,
              color: _matchCase 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            iconSize: 18,
            tooltip: 'Match Case',
          ),
          IconButton(
            onPressed: _toggleWholeWord,
            icon: Icon(
              Icons.border_outer,
              color: _wholeWord 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            iconSize: 18,
            tooltip: 'Match Whole Word',
          ),

          // Close button
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            iconSize: 18,
            tooltip: 'Close (Escape)',
          ),
        ],
      ),
    );
  }

  void updateMatchInfo(int currentMatch, int totalMatches) {
    if (mounted) {
      setState(() {
        _currentMatch = currentMatch;
        _totalMatches = totalMatches;
      });
    }
  }
}