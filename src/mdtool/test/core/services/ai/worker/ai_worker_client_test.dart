import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/core/services/ai/worker/ai_worker_client.dart';
import 'package:mdtool/core/services/ai/worker/ai_worker_types.dart';
import 'package:mdtool/core/services/ai/worker/sidecar_transport.dart';

class _FakeTransport implements SidecarTransport {
  final _notif = StreamController<NotificationEvent>.broadcast();
  final List<({String method, Map<String, Object?> params})> calls = [];
  Object? nextResult;

  @override Stream<NotificationEvent> get notifications => _notif.stream;
  @override bool get isConnected => true;
  @override String get socketPath => 'fake';
  @override Future<void> connect() async {}
  @override Future<void> disconnect() async {}
  @override Future<Object?> request(String method, Map<String, Object?> params) async {
    calls.add((method: method, params: params));
    return nextResult;
  }
  void pushNotif(NotificationEvent e) => _notif.add(e);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('health() returns parsed status', () async {
    final t = _FakeTransport()..nextResult = {'ok': true, 'version': '0.1.0', 'sources': []};
    final c = AIWorkerClient(t);
    final h = await c.health();
    expect(h.ok, true);
    expect(h.version, '0.1.0');
  });

  test('refine() returns opId and exposes stream events filtered by opId', () async {
    final t = _FakeTransport()..nextResult = {'opId': 'op-1'};
    final c = AIWorkerClient(t);
    final ctrl = await c.refine(selection: 'hi', op: RefineOp.refine);
    expect(ctrl.opId, 'op-1');

    final events = <StreamEvent>[];
    final sub = ctrl.events.listen(events.add);
    t.pushNotif(NotificationEvent('stream.delta', {'opId': 'op-1', 'blockIdx': 0, 'deltaType': 'add', 'text': 'x'}));
    t.pushNotif(NotificationEvent('stream.delta', {'opId': 'other', 'blockIdx': 0, 'deltaType': 'add', 'text': 'NO'}));
    t.pushNotif(NotificationEvent('stream.done', {'opId': 'op-1', 'totalBlocks': 1, 'tokenUsage': {'input': 1, 'output': 1}, 'cost': 0.0}));
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(events.length, 2);
    expect(events[0], isA<StreamEventDelta>());
    expect((events[0] as StreamEventDelta).data.text, 'x');
    expect(events[1], isA<StreamEventDone>());
  });
}
