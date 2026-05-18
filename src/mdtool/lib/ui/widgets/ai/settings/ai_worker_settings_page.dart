import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mdtool/core/services/ai/worker/ai_worker_provider.dart';

class AIWorkerSettingsPage extends ConsumerStatefulWidget {
  const AIWorkerSettingsPage({super.key});
  @override
  ConsumerState<AIWorkerSettingsPage> createState() =>
      _AIWorkerSettingsPageState();
}

class _AIWorkerSettingsPageState extends ConsumerState<AIWorkerSettingsPage> {
  final _ctrl = TextEditingController();
  String _existingMasked = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final key = await ref.read(aiWorkerSecretsProvider).getAnthropicKey();
    setState(() {
      _existingMasked = (key != null && key.length > 8)
          ? '${key.substring(0, 4)}…${key.substring(key.length - 4)}'
          : (key == null ? '(not set)' : '****');
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(aiWorkerSecretsProvider)
          .setAnthropicKey(_ctrl.text.trim());
      _ctrl.clear();
      await _loadExisting();
      // Force a worker restart so the new key takes effect:
      ref.invalidate(aiWorkerClientProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    await ref.read(aiWorkerSecretsProvider).clearAnthropicKey();
    await _loadExisting();
    ref.invalidate(aiWorkerClientProvider);
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(aiWorkerClientProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anthropic API Key',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Current: $_existingMasked',
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
                controller: _ctrl,
                obscureText: true,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'sk-ant-…')),
            const SizedBox(height: 4),
            Row(children: [
              FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save')),
              const SizedBox(width: 8),
              TextButton(
                  onPressed: _clear, child: const Text('Clear')),
            ]),
            const Divider(height: 32),
            const Text('Sidecar Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            clientAsync.when(
              loading: () => const Text('Starting…'),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: Colors.red)),
              data: (client) => FutureBuilder(
                future: client.health(),
                builder: (ctx, snap) => Text(snap.hasData
                    ? 'Worker ${snap.data!.ok ? "✓ running" : "✗ unhealthy"} v${snap.data!.version}'
                    : 'Pinging…'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Logs',
                style: TextStyle(fontWeight: FontWeight.bold)),
            FutureBuilder(
              future: _logPath(),
              builder: (ctx, snap) => Text(snap.data ?? '…',
                  style: const TextStyle(fontSize: 12)),
            ),
          ]),
    );
  }

  Future<String> _logPath() async {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '~';
      return '$home/Library/Logs/MDTool/ai-worker.log';
    } else if (Platform.isWindows) {
      final appData =
          Platform.environment['APPDATA'] ?? '%APPDATA%';
      return '$appData\\MDTool\\logs\\ai-worker.log';
    }
    return 'unsupported platform';
  }
}
