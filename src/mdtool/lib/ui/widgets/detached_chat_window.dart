import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/chat_service.dart';
import 'unified_chat_dialog.dart';

class DetachedChatWindow extends ConsumerStatefulWidget {
  final List<ChatMessage> initialMessages;
  final bool useDocumentContext;
  final bool useWebSearch;
  final Set<String> selectedDocuments;
  final List<AttachedFile> attachedFiles;

  const DetachedChatWindow({
    super.key,
    required this.initialMessages,
    required this.useDocumentContext,
    required this.useWebSearch,
    required this.selectedDocuments,
    required this.attachedFiles,
  });

  @override
  ConsumerState<DetachedChatWindow> createState() => _DetachedChatWindowState();
}

class _DetachedChatWindowState extends ConsumerState<DetachedChatWindow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close window',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt),
            onPressed: _reattachToMainWindow,
            tooltip: 'Reattach to main window',
          ),
        ],
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: UnifiedChatDialog(
          isDetached: true,
          initialUseDocumentContext: widget.useDocumentContext,
          initialUseWebSearch: widget.useWebSearch,
          initialSelectedDocuments: widget.selectedDocuments,
          initialAttachedFiles: widget.attachedFiles,
        ),
      ),
    );
  }

  void _reattachToMainWindow() {
    // Close the detached window and return to previous screen
    Navigator.of(context).pop();
    
    // Show the unified chat dialog in the main window
    Future.delayed(const Duration(milliseconds: 100), () {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => UnifiedChatDialog(
            initialUseDocumentContext: widget.useDocumentContext,
            initialUseWebSearch: widget.useWebSearch,
            initialSelectedDocuments: widget.selectedDocuments,
            initialAttachedFiles: widget.attachedFiles,
          ),
        );
      }
    });
  }
}