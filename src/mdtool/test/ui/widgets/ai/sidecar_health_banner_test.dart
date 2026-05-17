import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/core/services/ai/worker/ai_worker_client.dart';
import 'package:mdtool/core/services/ai/worker/ai_worker_provider.dart';
import 'package:mdtool/core/services/ai/worker/sidecar_transport.dart';
import 'package:mdtool/ui/widgets/ai/sidecar_health_banner.dart';

void main() {
  testWidgets('shows nothing when worker is healthy', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        aiWorkerClientProvider.overrideWith((ref) async => _HealthyClient()),
      ],
      child: const MaterialApp(home: Scaffold(body: SidecarHealthBanner())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('AI worker offline'), findsNothing);
  });

  testWidgets('shows banner when health returns ok=false', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        aiWorkerClientProvider.overrideWith((ref) async => _UnhealthyClient()),
      ],
      child: const MaterialApp(home: Scaffold(body: SidecarHealthBanner())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('AI worker offline'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _HealthyClient extends AIWorkerClient {
  _HealthyClient() : super(SidecarTransport(socketPath: '/tmp/never-connected.sock'));
  @override Future<WorkerHealth> health() async => const WorkerHealth(ok: true, version: '0.1.0', sources: []);
}
class _UnhealthyClient extends AIWorkerClient {
  _UnhealthyClient() : super(SidecarTransport(socketPath: '/tmp/never-connected.sock'));
  @override Future<WorkerHealth> health() async => const WorkerHealth(ok: false, version: '0.1.0', sources: []);
}
