/// Dart-side mirror of sidecar/src/rpc/methods.ts types.
/// Hand-maintained for now; consider codegen when surface grows.
library;

class RpcRequest {
  final int id;
  final String method;
  final Map<String, Object?>? params;
  RpcRequest({required this.id, required this.method, this.params});

  Map<String, Object?> toJson() => {
    'jsonrpc': '2.0',
    'id': id,
    'method': method,
    if (params != null) 'params': params,
  };
}

class RpcError implements Exception {
  final int code;
  final String message;
  final Object? data;
  RpcError(this.code, this.message, [this.data]);
  @override String toString() => 'RpcError($code): $message';
}

enum RefineOp { refine, shorten, translate }

extension RefineOpWire on RefineOp {
  String get wire => switch (this) {
    RefineOp.refine => 'refine',
    RefineOp.shorten => 'shorten',
    RefineOp.translate => 'translate',
  };
}

class StreamDelta {
  final String opId;
  final int blockIdx;
  final String deltaType;   // "add" | "del"
  final String text;
  const StreamDelta(this.opId, this.blockIdx, this.deltaType, this.text);
}

class StreamDone {
  final String opId;
  final int totalBlocks;
  final ({int input, int output}) tokenUsage;
  final double cost;
  const StreamDone(this.opId, this.totalBlocks, this.tokenUsage, this.cost);
}

class StreamErrorEvent {
  final String opId;
  final String message;
  final bool recoverable;
  const StreamErrorEvent(this.opId, this.message, this.recoverable);
}

sealed class StreamEvent {}
class StreamEventDelta extends StreamEvent { final StreamDelta data; StreamEventDelta(this.data); }
class StreamEventDone extends StreamEvent { final StreamDone data; StreamEventDone(this.data); }
class StreamEventError extends StreamEvent { final StreamErrorEvent data; StreamEventError(this.data); }
