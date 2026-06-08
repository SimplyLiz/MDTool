import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AIWorkerSecrets {
  AIWorkerSecrets({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          mOptions: MacOsOptions(
            synchronizable: false,
            useDataProtectionKeyChain: false,
          ),
          wOptions: WindowsOptions(),
        );
  final FlutterSecureStorage _storage;

  static const _kAnthropic = 'mdtool.ai.anthropic_api_key';

  Future<String?> getAnthropicKey() => _storage.read(key: _kAnthropic);
  Future<void> setAnthropicKey(String value) => _storage.write(key: _kAnthropic, value: value);
  Future<void> clearAnthropicKey() => _storage.delete(key: _kAnthropic);
}
