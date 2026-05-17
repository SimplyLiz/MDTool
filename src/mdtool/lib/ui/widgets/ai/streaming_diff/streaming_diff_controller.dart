import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:mdtool/core/services/ai/worker/ai_worker_client.dart';
import 'package:mdtool/core/services/ai/worker/ai_worker_types.dart';

import 'streaming_diff_model.dart';

class StreamingDiffController extends ChangeNotifier {
  StreamingDiffController(this._client);
  final AIWorkerClient _client;

  StreamingDiffState? _state;
  StreamingDiffState? get state => _state;
  RefineHandle? _handle;
  StreamSubscription<StreamEvent>? _sub;

  Future<void> start({
    required String selection,
    required RefineOp op,
    String? extra,
  }) async {
    await _disposeCurrent();
    _handle = await _client.refine(selection: selection, op: op, extra: extra);
    _state = StreamingDiffState.start(opId: _handle!.opId, originalText: selection);
    notifyListeners();
    _sub = _handle!.events.listen(_onEvent);
  }

  void _onEvent(StreamEvent e) {
    final s = _state;
    if (s == null) return;
    switch (e) {
      case StreamEventDelta(:final data):
        _state = s.applyDelta(blockIdx: data.blockIdx, deltaType: data.deltaType, text: data.text);
      case StreamEventDone(:final data):
        _state = s.markComplete(totalBlocks: data.totalBlocks);
      case StreamEventError(:final data):
        _state = s.markError(data.message);
    }
    notifyListeners();
  }

  Future<void> cancel() async => await _handle?.cancel();
  void accept(int blockIdx) { _state = _state?.accept(blockIdx: blockIdx); notifyListeners(); }
  void reject(int blockIdx) { _state = _state?.reject(blockIdx: blockIdx); notifyListeners(); }

  Future<void> _disposeCurrent() async {
    await _sub?.cancel(); _sub = null;
    _handle = null; _state = null;
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
