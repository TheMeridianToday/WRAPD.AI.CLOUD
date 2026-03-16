// ─────────────────────────────────────────────────────────
//  WRAPD — Error Boundary Widget
//  Catches and displays errors gracefully in widgets
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../services/crash_reporting_service.dart';
import 'shared_components.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, Object, VoidCallback) fallbackBuilder;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder = _defaultFallbackBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();

  static Widget _defaultFallbackBuilder(BuildContext context, Object error, VoidCallback onRetry) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unexpected Error',
        message: 'Something went wrong while rendering this component.',
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
    );
  }
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  void _resetError() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallbackBuilder(context, _error!, _resetError);
    }
    
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    FlutterError.onError = _handleFlutterError;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    _error = details.exception;
    
    // Report the error
    CrashReportingService.reportError(
      error: details.exception,
      stackTrace: details.stack,
      context: 'Widget Error Boundary',
      fatal: true,
    );
    
    setState(() {});
    
    // Call custom error handler
    widget.onError?.call();
  }

  @override
  void dispose() {
    // Note: This might overwrite other global error handlers
    // In a multi-boundary app, you'd want a more sophisticated approach
    super.dispose();
  }
}
