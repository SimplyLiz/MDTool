import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/core/services/ai/worker/sidecar_lifecycle.dart';

void main() {
  test('spawns once and reports started state', () async {
    var spawnCalls = 0;
    final mgr = SidecarLifecycleManager(
      binaryPath: () => '/fake/binary',
      socketPath: '/tmp/fake.sock',
      spawnFn: (bin, args) async {
        spawnCalls++;
        return _FakeProcess();
      },
      apiKeyResolver: () async => 'sk-fake',
    );
    final status = await mgr.start();
    expect(status.running, true);
    expect(spawnCalls, 1);
    await mgr.stop();
  });

  test('emits restart event when process exits', () async {
    var spawnCalls = 0;
    final exits = StreamController<int>();
    final mgr = SidecarLifecycleManager(
      binaryPath: () => '/fake/binary',
      socketPath: '/tmp/fake.sock',
      spawnFn: (bin, args) async {
        spawnCalls++;
        return _FakeProcess(exits: exits.stream);
      },
      apiKeyResolver: () async => 'sk-fake',
      restartBackoff: const Duration(milliseconds: 5),
    );
    await mgr.start();
    exits.add(137);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(spawnCalls, greaterThanOrEqualTo(2));
    await mgr.stop();
  });
}

class _FakeProcess implements SidecarProcess {
  _FakeProcess({Stream<int>? exits}) : _exits = exits ?? const Stream.empty();
  final Stream<int> _exits;
  @override Stream<int> get exitCode => _exits;
  @override Future<void> kill() async {}
}
