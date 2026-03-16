// ─────────────────────────────────────────────────────────
//  WRAPD — Crash Reporting Service
//  Provides error tracking and crash analytics
// ─────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'logger_service.dart';

class CrashReportingService {
  static const String _crashBoxKey = 'crash_reports';
  static bool _initialized = false;

  /// Initialize crash reporting service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    await Hive.openBox<String>(_crashBoxKey);
    
    // Set up global error handlers
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
    
    _initialized = true;
    
    // Report any pending crashes from previous runs
    _reportPendingCrashes();
  }

  /// Report an error or crash
  static Future<void> reportError({
    required Object error,
    StackTrace? stackTrace,
    String context = 'Unknown',
    bool fatal = false,
    Map<String, dynamic>? extra,
  }) async {
    final errorReport = {
      'timestamp': DateTime.now().toIso8601String(),
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'stack_trace': stackTrace?.toString(),
      'context': context,
      'fatal': fatal,
      'platform': defaultTargetPlatform.toString(),
      'version': '1.0.0',
      'extra': extra ?? {},
    };

    // Store locally for retry
    _storeCrashLocally(errorReport);

    // In a real implementation, send to Sentry/Firebase Crashlytics
    await _sendCrashReport(errorReport);
  }

  /// Handle Flutter framework errors
  static void _handleFlutterError(FlutterErrorDetails details) {
    reportError(
      error: details.exception,
      stackTrace: details.stack,
      context: 'Flutter Framework',
      fatal: true,
      extra: {
        'library': details.library,
        'summary': details.summary,
      },
    );
  }

  /// Handle platform errors
  static bool _handlePlatformError(Object error, StackTrace stackTrace) {
    reportError(
      error: error,
      stackTrace: stackTrace,
      context: 'Platform Error',
      fatal: true,
    );
    return true; // Handled
  }

  /// Store crash locally for retry
  static void _storeCrashLocally(Map<String, dynamic> errorReport) {
    try {
      final box = Hive.box<String>(_crashBoxKey);
      final reportId = DateTime.now().millisecondsSinceEpoch.toString();
      box.put(reportId, jsonEncode(errorReport));
    } catch (e) {
      // If storage fails, we can't do much
    }
  }

  /// Send crash report to external service
  static Future<void> _sendCrashReport(Map<String, dynamic> errorReport) async {
    try {
      // In production, this would send to Sentry, Firebase Crashlytics, etc.
      // Simulating network request
      
      if (kDebugMode) {
        WrapdLogger.e('CRASH REPORT: ${errorReport['error_message']}');
      }
      
      // Remove from local storage after successful send
      _removeCrashReport(errorReport);
    } catch (e) {
      // Retry logic would go here
    }
  }

  /// Report pending crashes from previous sessions
  static Future<void> _reportPendingCrashes() async {
    try {
      final box = Hive.box<String>(_crashBoxKey);
      final reports = box.values.toList();
      
      for (final reportJson in reports) {
        final report = jsonDecode(reportJson) as Map<String, dynamic>;
        await _sendCrashReport(report);
      }
      
      await box.clear();
    } catch (e) {
      // Ignore errors during crash recovery
    }
  }

  /// Remove crash report after successful sending
  static void _removeCrashReport(Map<String, dynamic> errorReport) {
    try {
      final box = Hive.box<String>(_crashBoxKey);
      final reports = box.values.toList();
      
      for (int i = 0; i < reports.length; i++) {
        final report = jsonDecode(reports[i]) as Map<String, dynamic>;
        if (report['timestamp'] == errorReport['timestamp']) {
          box.deleteAt(i);
          break;
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Record custom analytics event
  static void recordEvent({
    required String name,
    Map<String, dynamic>? properties,
  }) {
    final event = {
      'event_name': name,
      'timestamp': DateTime.now().toIso8601String(),
      'properties': properties ?? {},
    };
    
    if (kDebugMode) {
      WrapdLogger.i('ANALYTICS EVENT: $event');
    }
    
    // In production, send to analytics service
    _storeAnalyticsEvent(event);
  }

  /// Store analytics event locally
  static void _storeAnalyticsEvent(Map<String, dynamic> event) {
    // Similar to crash storage but for analytics
    // Would be batched and sent periodically
  }
}
