import 'dart:async';
import 'dart:io';

abstract class SidecarProcess {
  Stream<int> get exitCode;
  Future<void> kill();
}

class _RealProcess implements SidecarProcess {
  _RealProcess(this._p);
  final Process _p;
  @override
  Stream<int> get exitCode async* {
    yield await _p.exitCode;
  }

  @override
  Future<void> kill() async {
    _p.kill();
    await _p.exitCode;
  }
}

typedef SpawnFn = Future<SidecarProcess> Function(
    String binary, List<String> args);

class SidecarStatus {
  final bool running;
  final String? lastError;
  const SidecarStatus({required this.running, this.lastError});
}

class SidecarLifecycleManager {
  SidecarLifecycleManager({
    required this.binaryPath,
    required this.socketPath,
    required this.apiKeyResolver,
    SpawnFn? spawnFn,
    this.restartBackoff = const Duration(seconds: 2),
  }) : spawnFn = spawnFn ?? _defaultSpawn;

  final String Function() binaryPath;
  final String socketPath;
  final Future<String> Function() apiKeyResolver;
  final SpawnFn spawnFn;
  final Duration restartBackoff;

  SidecarProcess? _proc;
  bool _stopRequested = false;
  final _statusCtrl = StreamController<SidecarStatus>.broadcast();

  Stream<SidecarStatus> get statusStream => _statusCtrl.stream;

  Future<SidecarStatus> start() async {
    _stopRequested = false;
    return _spawn();
  }

  Future<void> stop() async {
    _stopRequested = true;
    final p = _proc;
    _proc = null;
    await p?.kill();
    _statusCtrl.add(const SidecarStatus(running: false));
  }

  Future<SidecarStatus> _spawn() async {
    try {
      await apiKeyResolver();
      final proc = await spawnFn(binaryPath(), ['--socket', socketPath]);
      _proc = proc;
      unawaited(proc.exitCode.first.then(_onExit).catchError((_) {}));
      const status = SidecarStatus(running: true);
      _statusCtrl.add(status);
      return status;
    } catch (e) {
      final status = SidecarStatus(running: false, lastError: e.toString());
      _statusCtrl.add(status);
      return status;
    }
  }

  Future<void> _onExit(int code) async {
    _statusCtrl.add(SidecarStatus(running: false, lastError: 'exit $code'));
    if (_stopRequested) return;
    await Future<void>.delayed(restartBackoff);
    if (_stopRequested) return;
    await _spawn();
  }

  static Future<SidecarProcess> _defaultSpawn(
      String binary, List<String> args) async {
    final env = Map<String, String>.from(Platform.environment);
    final p = await Process.start(binary, args, environment: env);
    return _RealProcess(p);
  }
}
