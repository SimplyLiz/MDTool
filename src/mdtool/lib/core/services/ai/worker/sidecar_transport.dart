import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ai_worker_types.dart';

class NotificationEvent {
  final String method;
  final Object? params;
  NotificationEvent(this.method, this.params);
}

class SidecarTransport {
  SidecarTransport({required this.socketPath});

  /// Unix socket path on macOS; for Windows pass the named-pipe path
  /// (e.g. r'\\.\pipe\mdtool-aiworker') — Dart's `Socket.connect` on
  /// `InternetAddressType.unix` does not handle named pipes; on Windows we
  /// use a different code path via `Socket.connect('127.0.0.1', port)` if the
  /// sidecar listens on TCP. Phase 1 uses Unix-sockets on macOS only; Windows
  /// path lands in Task B6 (Windows fallback).
  final String socketPath;

  Socket? _sock;
  final _pendings = <int, Completer<Object?>>{};
  int _nextId = 1;
  final _notifCtrl = StreamController<NotificationEvent>.broadcast();
  StringBuffer _buf = StringBuffer();

  Stream<NotificationEvent> get notifications => _notifCtrl.stream;
  bool get isConnected => _sock != null;

  Future<void> connect() async {
    _sock = await Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix), 0,
    );
    _sock!.listen(_onData, onDone: _onClose, onError: (_) => _onClose());
  }

  Future<Object?> request(String method, Map<String, Object?> params) {
    final sock = _sock;
    if (sock == null) throw StateError('Transport not connected');
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pendings[id] = completer;
    final req = RpcRequest(id: id, method: method, params: params);
    sock.add(utf8.encode('${json.encode(req.toJson())}\n'));
    return completer.future;
  }

  Future<void> disconnect() async {
    final s = _sock;
    _sock = null;
    await s?.flush();
    await s?.close();
    for (final c in _pendings.values) {
      if (!c.isCompleted) c.completeError(StateError('Transport closed'));
    }
    _pendings.clear();
  }

  void _onData(List<int> chunk) {
    _buf.write(utf8.decode(chunk, allowMalformed: true));
    while (true) {
      final s = _buf.toString();
      final nl = s.indexOf('\n');
      if (nl < 0) break;
      final line = s.substring(0, nl);
      _buf = StringBuffer(s.substring(nl + 1));
      if (line.trim().isEmpty) continue;
      _handleMessage(json.decode(line) as Map<String, Object?>);
    }
  }

  void _handleMessage(Map<String, Object?> msg) {
    final id = msg['id'];
    if (id != null) {
      final completer = _pendings.remove(id as int);
      if (completer == null) return;
      if (msg.containsKey('error')) {
        final err = msg['error'] as Map<String, Object?>;
        completer.completeError(RpcError(err['code'] as int, err['message'] as String, err['data']));
      } else {
        completer.complete(msg['result']);
      }
    } else if (msg['method'] is String) {
      _notifCtrl.add(NotificationEvent(msg['method'] as String, msg['params']));
    }
  }

  void _onClose() {
    final s = _sock;
    _sock = null;
    s?.destroy();
    for (final c in _pendings.values) {
      if (!c.isCompleted) c.completeError(StateError('Transport closed'));
    }
    _pendings.clear();
  }
}
