import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class PDFExportService {
  static const double _defaultMargin = 72.0; // 1 inch in points
  static const double _defaultFontSize = 12.0;
  static const double _defaultLineHeight = 1.4;

  static Future<void> exportMarkdownToPDF({
    required String markdownContent,
    required String fileName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    double margin = _defaultMargin,
    double fontSize = _defaultFontSize,
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);

      // Parse markdown to HTML-like structure
      final document = md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
        encodeHtml: false,
      );
      final nodes = document.parseLines(markdownContent.split('\n'));
      
      onProgress?.call(0.3);

      // Create PDF document
      final pdf = pw.Document();
      
      // Use base fonts (no external font loading needed)
      final fontRegular = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();
      final fontItalic = pw.Font.helveticaOblique();
      final fontMono = pw.Font.courier();
      
      onProgress?.call(0.5);

      // Convert nodes to PDF widgets
      final List<pw.Widget> pdfWidgets = [];
      for (final node in nodes) {
        final widget = await _convertNodeToPDFWidget(
          node,
          fontRegular: fontRegular,
          fontBold: fontBold,
          fontItalic: fontItalic,
          fontMono: fontMono,
          fontSize: fontSize,
        );
        if (widget != null) {
          pdfWidgets.add(widget);
        }
      }
      
      onProgress?.call(0.7);

      // Add all content to a single MultiPage - it will handle page breaks automatically
      pdf.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) => pdfWidgets,
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            italic: fontItalic,
            boldItalic: fontBold, // Fallback
          ),
        ),
      );
      
      onProgress?.call(0.9);

      // Save PDF file
      await _savePDFFile(pdf, fileName);
      
      onProgress?.call(1.0);
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  static Future<pw.Widget?> _convertNodeToPDFWidget(
    md.Node node, {
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontItalic,
    required pw.Font fontMono,
    required double fontSize,
  }) async {
    if (node is md.Element) {
      switch (node.tag) {
        case 'h1':
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 16),
            child: pw.Text(
              node.textContent,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: fontSize * 2,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        
        case 'h2':
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 14),
            child: pw.Text(
              node.textContent,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: fontSize * 1.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        
        case 'h3':
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            child: pw.Text(
              node.textContent,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: fontSize * 1.3,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        
        case 'h4':
        case 'h5':
        case 'h6':
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Text(
              node.textContent,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: fontSize * 1.1,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        
        case 'p':
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Text(
              node.textContent,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: fontSize,
                height: _defaultLineHeight,
              ),
              softWrap: true,
            ),
          );
        
        case 'code':
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              node.textContent,
              style: pw.TextStyle(
                font: fontMono,
                fontSize: fontSize * 0.9,
              ),
              softWrap: true,
            ),
          );
        
        case 'pre':
          // Split very long code blocks to prevent page overflow
          final content = node.textContent;
          const maxLines = 40; // Reasonable max lines per code block
          final lines = content.split('\n');
          
          if (lines.length > maxLines) {
            // Split into chunks
            final chunks = <String>[];
            for (int i = 0; i < lines.length; i += maxLines) {
              final end = (i + maxLines < lines.length) ? i + maxLines : lines.length;
              chunks.add(lines.sublist(i, end).join('\n'));
            }
            
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: chunks.map((chunk) => pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Text(
                  chunk,
                  style: pw.TextStyle(
                    font: fontMono,
                    fontSize: fontSize * 0.9,
                  ),
                  softWrap: true,
                ),
              )).toList(),
            );
          } else {
            return pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              margin: const pw.EdgeInsets.symmetric(vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Text(
                content,
                style: pw.TextStyle(
                  font: fontMono,
                  fontSize: fontSize * 0.9,
                ),
                softWrap: true,
              ),
            );
          }
        
        case 'blockquote':
          return pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 8),
            padding: const pw.EdgeInsets.only(left: 16, top: 8, bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.blue, width: 4),
              ),
            ),
            child: pw.Text(
              node.textContent,
              style: pw.TextStyle(
                font: fontItalic,
                fontSize: fontSize,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
              softWrap: true,
            ),
          );
        
        case 'ul':
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: node.children?.map((child) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16, bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(font: fontRegular, fontSize: fontSize)),
                      pw.Expanded(
                        child: pw.Text(
                          child.textContent,
                          style: pw.TextStyle(font: fontRegular, fontSize: fontSize),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList() ?? [],
            ),
          );
        
        case 'ol':
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: node.children?.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final child = entry.value;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16, bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('$index. ', style: pw.TextStyle(font: fontRegular, fontSize: fontSize)),
                      pw.Expanded(
                        child: pw.Text(
                          child.textContent,
                          style: pw.TextStyle(font: fontRegular, fontSize: fontSize),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList() ?? [],
            ),
          );
        
        case 'hr':
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 16),
            child: pw.Divider(color: PdfColors.grey400),
          );
        
        case 'table':
          return _buildPDFTable(node, fontRegular, fontBold, fontSize);
        
        case 'img':
          return await _buildPDFImage(node);
        
        default:
          // Handle unknown elements as text
          if (node.textContent.trim().isNotEmpty) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                node.textContent,
                style: pw.TextStyle(font: fontRegular, fontSize: fontSize),
              ),
            );
          }
      }
    } else if (node is md.Text) {
      if (node.text.trim().isNotEmpty) {
        return pw.Text(
          node.text,
          style: pw.TextStyle(font: fontRegular, fontSize: fontSize),
          softWrap: true,
        );
      }
    }
    
    return null;
  }

  static pw.Widget _buildPDFTable(md.Element tableNode, pw.Font fontRegular, pw.Font fontBold, double fontSize) {
    final rows = <List<String>>[];
    
    // Extract table data
    for (final child in tableNode.children ?? []) {
      if (child is md.Element) {
        if (child.tag == 'thead' || child.tag == 'tbody') {
          for (final rowElement in child.children ?? []) {
            if (rowElement is md.Element && rowElement.tag == 'tr') {
              final rowData = <String>[];
              for (final cellElement in rowElement.children ?? []) {
                if (cellElement is md.Element && (cellElement.tag == 'th' || cellElement.tag == 'td')) {
                  rowData.add(cellElement.textContent.trim());
                }
              }
              if (rowData.isNotEmpty) {
                rows.add(rowData);
              }
            }
          }
        }
      }
    }
    
    if (rows.isEmpty) return pw.SizedBox();
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Table.fromTextArray(
        data: rows,
        border: pw.TableBorder.all(color: PdfColors.grey400),
        headerStyle: pw.TextStyle(font: fontBold, fontSize: fontSize),
        cellStyle: pw.TextStyle(font: fontRegular, fontSize: fontSize),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.all(6),
        columnWidths: rows.first.asMap().map((index, _) => 
          MapEntry(index, const pw.FlexColumnWidth())
        ),
      ),
    );
  }

  static Future<void> _savePDFFile(pw.Document pdf, String fileName) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF as...',
      fileName: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = File(result);
      final pdfData = await pdf.save();
      await file.writeAsBytes(pdfData);
    } else {
      throw Exception('PDF save cancelled by user');
    }
  }

  static Future<void> showPrintPreview({
    required String markdownContent,
    required String fileName,
    required BuildContext context,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    double margin = _defaultMargin,
    double fontSize = _defaultFontSize,
  }) async {
    try {
      // Generate PDF document
      final document = md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
        encodeHtml: false,
      );
      final nodes = document.parseLines(markdownContent.split('\n'));
      
      final pdf = pw.Document();
      
      // Use base fonts (no external font loading needed)
      final fontRegular = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();
      final fontItalic = pw.Font.helveticaOblique();
      final fontMono = pw.Font.courier();
      
      // Convert to PDF widgets
      final List<pw.Widget> pdfWidgets = [];
      for (final node in nodes) {
        final widget = await _convertNodeToPDFWidget(
          node,
          fontRegular: fontRegular,
          fontBold: fontBold,
          fontItalic: fontItalic,
          fontMono: fontMono,
          fontSize: fontSize,
        );
        if (widget != null) {
          pdfWidgets.add(widget);
        }
      }
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) => pdfWidgets,
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            italic: fontItalic,
            boldItalic: fontBold,
          ),
        ),
      );

      // Show print preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );
    } catch (e) {
      throw Exception('Failed to show print preview: $e');
    }
  }

  static Future<pw.Widget?> _buildPDFImage(md.Element imgNode) async {
    final String? src = imgNode.attributes['src'];
    final String? alt = imgNode.attributes['alt'];
    
    if (src == null) return null;
    
    try {
      pw.ImageProvider? imageProvider;
      
      if (src.startsWith('http://') || src.startsWith('https://')) {
        // Network image
        final response = await http.get(Uri.parse(src));
        if (response.statusCode == 200) {
          imageProvider = pw.MemoryImage(response.bodyBytes);
        }
      } else if (src.startsWith('file://') || !src.contains('://')) {
        // Local file
        final file = File(src.startsWith('file://') ? src.substring(7) : src);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          imageProvider = pw.MemoryImage(bytes);
        }
      }
      
      if (imageProvider != null) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                constraints: const pw.BoxConstraints(maxHeight: 400),
                child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
              ),
              if (alt?.isNotEmpty == true) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  alt!,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      }
    } catch (e) {
      // If image loading fails, show alt text or placeholder
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Container(
          height: 60,
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Center(
            child: pw.Text(
              alt?.isNotEmpty == true ? 'Image: $alt' : 'Image not available',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }
    
    return null;
  }
}