import 'dart:async';

import 'ai_worker_types.dart';
import 'sidecar_transport.dart';

class WorkerHealth {
  final bool ok;
  final String version;
  final List<Map<String, Object?>> sources;
  const WorkerHealth({required this.ok, required this.version, required this.sources});
}

class RefineHandle {
  final String opId;
  final Stream<StreamEvent> events;
  final Future<void> Function() cancel;
  RefineHandle({required this.opId, required this.events, required this.cancel});
}

class AIWorkerClient {
  AIWorkerClient(this._t);
  final SidecarTransport _t;

  Future<WorkerHealth> health() async {
    final r = (await _t.request('health', {})) as Map<String, Object?>;
    return WorkerHealth(
      ok: r['ok'] as bool,
      version: r['version'] as String,
      sources: ((r['sources'] as List?) ?? []).cast<Map<String, Object?>>(),
    );
  }

  Future<RefineHandle> refine({
    required String selection,
    required RefineOp op,
    String? extra,
  }) async {
    final r = (await _t.request('refine', {
      'selection': selection,
      'op': op.wire,
      if (extra != null) 'extra': extra,
    })) as Map<String, Object?>;
    final opId = r['opId'] as String;
    final stream = _t.notifications
        .where((n) => (n.params as Map?)?['opId'] == opId)
        .map<StreamEvent?>(_mapNotif)
        .where((e) => e != null)
        .cast<StreamEvent>();
    return RefineHandle(
      opId: opId,
      events: stream,
      cancel: () async { await _t.request('cancel', {'opId': opId}); },
    );
  }

  StreamEvent? _mapNotif(NotificationEvent n) {
    final p = n.params as Map<String, Object?>;
    switch (n.method) {
      case 'stream.delta':
        return StreamEventDelta(StreamDelta(
          p['opId'] as String,
          (p['blockIdx'] as num).toInt(),
          p['deltaType'] as String,
          p['text'] as String,
        ));
      case 'stream.done':
        final u = p['tokenUsage'] as Map<String, Object?>;
        return StreamEventDone(StreamDone(
          p['opId'] as String,
          (p['totalBlocks'] as num).toInt(),
          (input: (u['input'] as num).toInt(), output: (u['output'] as num).toInt()),
          (p['cost'] as num).toDouble(),
        ));
      case 'stream.error':
        return StreamEventError(StreamErrorEvent(
          p['opId'] as String,
          p['message'] as String,
          p['recoverable'] as bool,
        ));
      default:
        return null;
    }
  }
}
