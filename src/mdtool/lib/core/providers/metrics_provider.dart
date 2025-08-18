import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/metrics_service.dart';

/// Provider for the MetricsService instance
final metricsServiceProvider = Provider<MetricsService>((ref) {
  return MetricsService.instance;
});

/// Provider for current usage summary
final usageSummaryProvider = StreamProvider<UsageSummary>((ref) {
  final metricsService = ref.watch(metricsServiceProvider);
  
  // Create a stream that updates when usage changes
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return metricsService.getUsageSummary();
  });
});

/// Provider for usage limits
final usageLimitsProvider = StateNotifierProvider<UsageLimitsNotifier, UsageLimits>((ref) {
  final metricsService = ref.watch(metricsServiceProvider);
  return UsageLimitsNotifier(metricsService);
});

/// Notifier for managing usage limits
class UsageLimitsNotifier extends StateNotifier<UsageLimits> {
  final MetricsService _metricsService;

  UsageLimitsNotifier(this._metricsService) : super(const UsageLimits()) {
    _loadLimits();
  }

  void _loadLimits() async {
    await _metricsService.initialize();
    state = _metricsService.limits;
  }

  Future<void> updateLimits(UsageLimits newLimits) async {
    await _metricsService.updateLimits(newLimits);
    state = newLimits;
  }
}

/// Provider for recent token usages
final recentUsagesProvider = Provider<List<TokenUsage>>((ref) {
  final metricsService = ref.watch(metricsServiceProvider);
  return metricsService.getRecentUsages(limit: 10);
});

/// Provider to check if usage is currently blocked
final isUsageBlockedProvider = Provider<bool>((ref) {
  final metricsService = ref.watch(metricsServiceProvider);
  return metricsService.isUsageBlocked();
});