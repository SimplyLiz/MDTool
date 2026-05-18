import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/core/services/ai/worker/sidecar_transport.dart';

void main() {
  test('roundtrips request and response', () async {
    final socketPath = '/tmp/mdtool-test-${DateTime.now().microsecondsSinceEpoch}.sock';
    final server = await ServerSocket.bind(InternetAddress(socketPath, type: InternetAddressType.unix), 0);
    server.listen((sock) {
      sock.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        final req = json.decode(line);
        final reply = {'jsonrpc': '2.0', 'id': req['id'], 'result': {'echoed': req['method']}};
        sock.add(utf8.encode(json.encode(reply) + '\n'));
      });
    });

    final t = SidecarTransport(socketPath: socketPath);
    await t.connect();
    final result = await t.request('ping', {});
    expect(result, equals({'echoed': 'ping'}));
    await t.disconnect();
    await server.close();
  });

  test('routes notifications to a stream', () async {
    final socketPath = '/tmp/mdtool-test-${DateTime.now().microsecondsSinceEpoch}.sock';
    final server = await ServerSocket.bind(InternetAddress(socketPath, type: InternetAddressType.unix), 0);
    server.listen((sock) {
      sock.add(utf8.encode(json.encode({'jsonrpc': '2.0', 'method': 'stream.delta', 'params': {'opId': 'x', 'text': 'foo'}}) + '\n'));
    });

    final t = SidecarTransport(socketPath: socketPath);
    await t.connect();
    final ev = await t.notifications.first.timeout(const Duration(seconds: 1));
    expect(ev.method, 'stream.delta');
    expect((ev.params as Map)['text'], 'foo');
    await t.disconnect();
    await server.close();
  });
}
