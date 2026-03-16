// ─────────────────────────────────────────────────────────
//  WRAPD — Performance Monitoring Service
//  Tracks app performance metrics and bottlenecks
// ─────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'crash_reporting_service.dart';

class PerformanceService {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<double>> _metrics = {};
  static bool _initialized = false;

  /// Initialize performance monitoring
  static void initialize() {
    if (_initialized) return;
    
    // Set up navigation performance tracking
    WidgetsBinding.instance.addObserver(
      PerformanceWidgetsBindingObserver(),
    );
    
    _initialized = true;
  }

  /// Start timing a performance metric
  static void startTimer(String metricName) {
    _timers[metricName] = Stopwatch()..start();
  }

  /// Stop timing and record metric
  static double stopTimer(String metricName) {
    final timer = _timers[metricName];
    if (timer == null) return 0.0;
    
    timer.stop();
    final duration = timer.elapsedMilliseconds.toDouble();
    
    _metrics.putIfAbsent(metricName, () => []).add(duration);
    _timers.remove(metricName);
    
    // Report significant performance issues
    if (duration > 1000) { // More than 1 second
      CrashReportingService.reportError(
        error: Exception('Performance issue detected'),
        context: 'PerformanceService',
        fatal: false,
        extra: {
          'metric_name': metricName,
          'duration_ms': duration,
          'threshold_ms': 1000,
        },
      );
    }
    
    return duration;
  }

  /// Get performance statistics for a metric
  static Map<String, dynamic> getMetricStats(String metricName) {
    final values = _metrics[metricName];
    if (values == null || values.isEmpty) {
      return {'count': 0, 'average': 0.0, 'max': 0.0, 'min': 0.0};
    }
    
    final sum = values.reduce((a, b) => a + b);
    final average = sum / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    
    return {
      'count': values.length,
      'average': average,
      'max': max,
      'min': min,
      'values': values,
    };
  }

  /// Record a navigation transition
  static void recordNavigation({
    required String fromRoute,
    required String toRoute,
    required Duration duration,
  }) {
    CrashReportingService.recordEvent(
      name: 'navigation_complete',
      properties: {
        'from': fromRoute,
        'to': toRoute,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }

  /// Record screen load time
  static void recordScreenLoad({
    required String screenName,
    required Duration loadTime,
    bool wasCached = false,
  }) {
    CrashReportingService.recordEvent(
      name: 'screen_load',
      properties: {
        'screen': screenName,
        'load_time_ms': loadTime.inMilliseconds,
        'cached': wasCached,
      },
    );
  }

  /// Record recording performance
  static void recordRecordingMetrics({
    required String sessionId,
    required Duration recordingDuration,
    required int audioSampleCount,
    double? audioQuality,
  }) {
    CrashReportingService.recordEvent(
      name: 'recording_performance',
      properties: {
        'session_id': sessionId,
        'recording_duration_ms': recordingDuration.inMilliseconds,
        'audio_samples': audioSampleCount,
        'audio_quality': audioQuality,
      },
    );
  }

  /// Measure widget build performance
  static PerformanceBuildTracker trackBuild(String widgetName) {
    return PerformanceBuildTracker(widgetName);
  }

  /// Clear all metrics (useful for testing)
  static void clearMetrics() {
    _timers.clear();
    _metrics.clear();
  }
}

/// Helper class for tracking build performance
class PerformanceBuildTracker {
  final String widgetName;
  final Stopwatch _stopwatch;

  PerformanceBuildTracker(this.widgetName) : _stopwatch = Stopwatch()..start();

  /// Call this when build is complete
  void complete() {
    _stopwatch.stop();
    final duration = _stopwatch.elapsedMilliseconds;
    
    PerformanceService._metrics
        .putIfAbsent('build_$widgetName', () => [])
        .add(duration.toDouble());
    
    if (duration > 16) { // More than 16ms (60fps threshold)
      CrashReportingService.recordEvent(
        name: 'slow_build',
        properties: {
          'widget': widgetName,
          'duration_ms': duration,
          'threshold_ms': 16,
        },
      );
    }
  }
}

/// WidgetsBinding observer for performance tracking
class PerformanceWidgetsBindingObserver extends WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    CrashReportingService.recordEvent(
      name: 'metrics_change',
      properties: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  @override
  void didHaveMemoryPressure() {
    CrashReportingService.reportError(
      error: Exception('Memory pressure detected'),
      context: 'PerformanceService',
      fatal: false,
    );
  }
}
