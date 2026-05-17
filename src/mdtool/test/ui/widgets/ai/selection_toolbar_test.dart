import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/ui/widgets/ai/ai_action.dart';
import 'package:mdtool/ui/widgets/ai/selection_toolbar.dart';

void main() {
  testWidgets('renders 3 Phase-1 actions and fires intent on tap', (tester) async {
    final calls = <AIAction>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SelectionToolbar(
        selectedText: 'hello',
        selectionStart: 0,
        selectionEnd: 5,
        onAction: (intent) => calls.add(intent.action),
      ),
    )));
    expect(find.text('Refine'), findsOneWidget);
    expect(find.text('Shorten'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);

    await tester.tap(find.text('Refine'));
    expect(calls, [AIAction.refine]);
  });
}
