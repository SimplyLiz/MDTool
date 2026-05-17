import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/core/services/ai/worker/ai_worker_client.dart';
import 'package:mdtool/core/services/ai/worker/ai_worker_types.dart';
import 'package:mdtool/core/services/ai/worker/sidecar_transport.dart';
import 'package:mdtool/ui/widgets/ai/streaming_diff/streaming_diff_controller.dart';
import 'package:mdtool/ui/widgets/ai/streaming_diff/streaming_diff_widget.dart';

void main() {
  testWidgets('shows incoming text and commits on accept', (tester) async {
    final transport = _ScriptedTransport();
    final client = AIWorkerClient(transport);
    final ctrl = StreamingDiffController(client);

    String? committed;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StreamingDiffWidget(
      controller: ctrl,
      onCommit: (s) => committed = s,
      onCancel: () {},
    ))));

    await ctrl.start(selection: 'old', op: RefineOp.refine);
    transport.fireDelta(opId: 'op-x', text: 'NEW');
    transport.fireDone(opId: 'op-x');
    await tester.pumpAndSettle();

    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('old'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pumpAndSettle();
    expect(committed, 'NEW');
  });
}

class _ScriptedTransport implements SidecarTransport {
  final _notif = StreamController<NotificationEvent>.broadcast();
  @override Stream<NotificationEvent> get notifications => _notif.stream;
  @override bool get isConnected => true;
  @override String get socketPath => 'fake';
  @override Future<void> connect() async {}
  @override Future<void> disconnect() async {}
  @override Future<Object?> request(String method, Map<String, Object?> params) async {
    if (method == 'refine') return {'opId': 'op-x'};
    if (method == 'cancel') return {'cancelled': true};
    return null;
  }
  void fireDelta({required String opId, required String text}) =>
    _notif.add(NotificationEvent('stream.delta', {'opId': opId, 'blockIdx': 0, 'deltaType': 'add', 'text': text}));
  void fireDone({required String opId}) =>
    _notif.add(NotificationEvent('stream.done', {'opId': opId, 'totalBlocks': 1, 'tokenUsage': {'input': 1, 'output': 1}, 'cost': 0.0}));

  // Satisfy interface for any unused members
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
