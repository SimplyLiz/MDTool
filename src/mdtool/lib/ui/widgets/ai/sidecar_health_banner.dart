import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mdtool/core/services/ai/worker/ai_worker_provider.dart';

class SidecarHealthBanner extends ConsumerWidget {
  const SidecarHealthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(aiWorkerClientProvider);
    return clientAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _banner(context, ref),
      data: (client) {
        return FutureBuilder(
          future: client.health(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            if (snap.data!.ok) return const SizedBox.shrink();
            return _banner(context, ref);
          },
        );
      },
    );
  }

  Widget _banner(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('AI worker offline')),
            TextButton(
              onPressed: () => ref.refresh(aiWorkerClientProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
