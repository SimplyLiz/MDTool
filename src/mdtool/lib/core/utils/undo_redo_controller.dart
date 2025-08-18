import 'package:flutter/material.dart';

class UndoRedoTextEditingController extends TextEditingController {
  final List<String> _history = [];
  int _currentIndex = -1;
  bool _isUndoRedoOperation = false;

  UndoRedoTextEditingController({String? text}) : super(text: text) {
    if (text != null && text.isNotEmpty) {
      _addToHistory(text);
    }
    addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isUndoRedoOperation) {
      _addToHistory(text);
    }
  }

  void _addToHistory(String newText) {
    // Don't add if it's the same as the current text
    if (_history.isNotEmpty && _currentIndex >= 0 && _history[_currentIndex] == newText) {
      return;
    }

    // Remove any history after current index (for when we're not at the end)
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Add new state
    _history.add(newText);
    _currentIndex = _history.length - 1;

    // Keep history size manageable
    if (_history.length > 100) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  void undo() {
    if (canUndo) {
      _currentIndex--;
      _isUndoRedoOperation = true;
      text = _history[_currentIndex];
      _isUndoRedoOperation = false;
    }
  }

  void redo() {
    if (canRedo) {
      _currentIndex++;
      _isUndoRedoOperation = true;
      text = _history[_currentIndex];
      _isUndoRedoOperation = false;
    }
  }

  void clearHistory() {
    _history.clear();
    _currentIndex = -1;
    if (text.isNotEmpty) {
      _addToHistory(text);
    }
  }

  @override
  void dispose() {
    removeListener(_onTextChanged);
    super.dispose();
  }
}