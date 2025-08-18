import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/providers/app_state_provider.dart';

class PDFExportDialog extends ConsumerStatefulWidget {
  const PDFExportDialog({super.key});

  @override
  ConsumerState<PDFExportDialog> createState() => _PDFExportDialogState();
}

class _PDFExportDialogState extends ConsumerState<PDFExportDialog> {
  PdfPageFormat _selectedFormat = PdfPageFormat.a4;
  double _margin = 72.0; // 1 inch
  double _fontSize = 12.0;
  bool _isExporting = false;
  double _exportProgress = 0.0;

  final List<MapEntry<String, PdfPageFormat>> _pageFormats = [
    const MapEntry('A4', PdfPageFormat.a4),
    const MapEntry('A3', PdfPageFormat.a3),
    const MapEntry('Letter', PdfPageFormat.letter),
    const MapEntry('Legal', PdfPageFormat.legal),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final fileName = appState.currentFile != null
        ? _getFileNameWithoutExtension(appState.currentFile!)
        : 'document';

    return AlertDialog(
      title: const Text('Export to PDF'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Format
            Text(
              'Page Format',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PdfPageFormat>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _pageFormats.map((format) {
                return DropdownMenuItem(
                  value: format.value,
                  child: Text(format.key),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFormat = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Margins
            Text(
              'Margins (inches)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _margin / 72.0, // Convert points to inches
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: '${(_margin / 72.0).toStringAsFixed(1)}"',
              onChanged: (value) {
                setState(() {
                  _margin = value * 72.0; // Convert inches to points
                });
              },
            ),
            const SizedBox(height: 16),

            // Font Size
            Text(
              'Font Size',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _fontSize,
              min: 8.0,
              max: 18.0,
              divisions: 10,
              label: '${_fontSize.toInt()}pt',
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),

            if (_isExporting) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exporting PDF...',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _exportProgress),
                  const SizedBox(height: 4),
                  Text(
                    '${(_exportProgress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Preview Button
        TextButton(
          onPressed: _isExporting ? null : () => _showPreview(appState, fileName),
          child: const Text('Preview'),
        ),
        // Cancel Button
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        // Export Button
        ElevatedButton(
          onPressed: _isExporting ? null : () => _exportPDF(appState, fileName),
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  String _getFileNameWithoutExtension(String filePath) {
    final fileName = filePath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
  }

  Future<void> _showPreview(appState, String fileName) async {
    try {
      await PDFExportService.showPrintPreview(
        markdownContent: appState.content,
        fileName: fileName,
        context: context,
        pageFormat: _selectedFormat,
        margin: _margin,
        fontSize: _fontSize,
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to show preview: $e');
      }
    }
  }

  Future<void> _exportPDF(appState, String fileName) async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    try {
      await PDFExportService.exportMarkdownToPDF(
        markdownContent: appState.content,
        fileName: fileName,
        pageFormat: _selectedFormat,
        margin: _margin,
        fontSize: _fontSize,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _exportProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportProgress = 0.0;
        });
        _showErrorDialog('Failed to export PDF: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}