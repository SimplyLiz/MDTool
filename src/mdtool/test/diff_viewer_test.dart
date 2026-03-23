import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/ui/widgets/diff_viewer.dart';
import 'package:mdtool/ui/pages/diff_comparison_page.dart';

void main() {
  group('DiffViewer Tests', () {
    testWidgets('DiffViewer displays two texts side by side', (WidgetTester tester) async {
      const leftText = 'Hello\nWorld\nTest';
      const rightText = 'Hello\nChanged World\nTest\nNew Line';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiffViewer(
              leftText: leftText,
              rightText: rightText,
              leftTitle: 'Left Side',
              rightTitle: 'Right Side',
            ),
          ),
        ),
      );

      // Verify titles are displayed
      expect(find.text('Left Side'), findsOneWidget);
      expect(find.text('Right Side'), findsOneWidget);

      // Verify content is displayed
      expect(find.text('Hello'), findsAtLeastNWidgets(2));
      expect(find.text('World'), findsOneWidget);
      expect(find.text('Changed World'), findsOneWidget);
      expect(find.text('New Line'), findsOneWidget);
    });

    testWidgets('AdvancedDiffViewer displays diff lines correctly', (WidgetTester tester) async {
      final diffLines = [
        const DiffLine(
          content: 'Same line',
          type: DiffLineType.unchanged,
          leftLineNumber: 1,
          rightLineNumber: 1,
        ),
        const DiffLine(
          content: 'Added line',
          type: DiffLineType.added,
          leftLineNumber: null,
          rightLineNumber: 2,
        ),
        const DiffLine(
          content: 'Removed line',
          type: DiffLineType.removed,
          leftLineNumber: 2,
          rightLineNumber: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedDiffViewer(
              diffLines: diffLines,
              leftTitle: 'Original',
              rightTitle: 'Modified',
            ),
          ),
        ),
      );

      // Verify content is displayed
      expect(find.text('Same line'), findsOneWidget);
      expect(find.text('Added line'), findsOneWidget);
      expect(find.text('Removed line'), findsOneWidget);

      // Check for diff prefixes
      expect(find.text(' '), findsWidgets); // Unchanged line prefix
      expect(find.text('+'), findsWidgets); // Added line prefix
      expect(find.text('-'), findsWidgets); // Removed line prefix
    });

    testWidgets('DiffComparisonPage loads initial files when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiffComparisonPage(
            initialLeftFile: '/path/to/file1.md',
            initialLeftContent: 'File 1 content\nLine 2',
            initialRightFile: '/path/to/file2.md',  
            initialRightContent: 'File 2 content\nModified line 2',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify file names are extracted correctly
      expect(find.text('file1.md'), findsOneWidget);
      expect(find.text('file2.md'), findsOneWidget);

      // Verify content is loaded
      expect(find.text('File 1 content'), findsOneWidget);
      expect(find.text('File 2 content'), findsOneWidget);
    });

    testWidgets('DiffComparisonPage falls back to sample data when no initial files', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiffComparisonPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify sample data is loaded
      expect(find.text('MD_Tool_v1.0.md'), findsOneWidget);
      expect(find.text('MD_Tool_v2.0.md'), findsOneWidget);
    });

    testWidgets('DiffComparisonPage has view mode dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiffComparisonPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify default mode is shown
      expect(find.text('TH Inline'), findsOneWidget);
      
      // Verify dropdown button exists
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('View mode dropdown shows all options', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiffComparisonPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap dropdown to open menu
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      // Verify all mode options appear in dropdown
      expect(find.text('TH Inline'), findsAtLeastNWidgets(1));
      expect(find.text('TH Side by Side'), findsOneWidget);
      expect(find.text('Full File'), findsOneWidget);
      expect(find.text('Enhanced'), findsOneWidget);
      expect(find.text('Legacy'), findsOneWidget);
    });
  });
}