import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'ai_worker_client.dart';
import 'ai_worker_secrets.dart';
import 'sidecar_lifecycle.dart';
import 'sidecar_transport.dart';

final aiWorkerSecretsProvider = Provider<AIWorkerSecrets>((ref) => AIWorkerSecrets());

final sidecarBinaryPathProvider = Provider<String Function()>((ref) {
  // macOS: <App>.app/Contents/Resources/ai-worker
  // Windows: alongside the .exe in resources\ai-worker.exe
  return () {
    if (Platform.isMacOS) {
      final exeDir = File(Platform.resolvedExecutable).parent.parent;
      return '${exeDir.path}/Resources/ai-worker';
    } else if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent;
      return '${exeDir.path}\\resources\\ai-worker.exe';
    }
    throw UnsupportedError('Unsupported platform for AI worker');
  };
});

final sidecarSocketPathProvider = FutureProvider<String>((ref) async {
  final tmp = await getTemporaryDirectory();
  return '${tmp.path}/mdtool-aiworker-$pid.sock';
});

final sidecarLifecycleProvider = FutureProvider<SidecarLifecycleManager>((ref) async {
  final socket = await ref.watch(sidecarSocketPathProvider.future);
  final secrets = ref.watch(aiWorkerSecretsProvider);
  final binPath = ref.watch(sidecarBinaryPathProvider);
  final mgr = SidecarLifecycleManager(
    binaryPath: binPath,
    socketPath: socket,
    apiKeyResolver: () async => await secrets.getAnthropicKey() ?? '',
  );
  await mgr.start();
  ref.onDispose(() => mgr.stop());
  return mgr;
});

final sidecarTransportProvider = FutureProvider<SidecarTransport>((ref) async {
  await ref.watch(sidecarLifecycleProvider.future);
  final socket = await ref.watch(sidecarSocketPathProvider.future);
  final t = SidecarTransport(socketPath: socket);
  // Retry connect briefly while the sidecar opens its socket.
  for (var i = 0; i < 20; i++) {
    try { await t.connect(); break; }
    catch (_) { await Future<void>.delayed(const Duration(milliseconds: 100)); }
  }
  if (!t.isConnected) throw StateError('Failed to connect to sidecar socket');
  ref.onDispose(() => t.disconnect());
  return t;
});

final aiWorkerClientProvider = FutureProvider<AIWorkerClient>((ref) async {
  final t = await ref.watch(sidecarTransportProvider.future);
  return AIWorkerClient(t);
});
