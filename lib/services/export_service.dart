import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import 'logger_service.dart';

// Conditional import: web_download_stub.dart provides a no-op on native,
// web_download_web.dart provides the real dart:html download on web.
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart'
    as web_download;

import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<bool> exportToText(WrapdSession session) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('WRAPD — Session Export');
      buffer.writeln('Title: ${session.title}');
      buffer.writeln('Date: ${session.createdAt}');
      buffer.writeln('Duration: ${session.duration.inMinutes}m');
      buffer.writeln('-----------------------------------');
      buffer.writeln();

      for (final segment in session.segments) {
        final ts = _formatDuration(segment.timestamp);
        buffer.writeln('[$ts] ${segment.speakerName}: ${segment.text}');
      }

      final text = buffer.toString();
      final fileName = 'wrapd_${session.id.substring(0, 8)}.txt';

      if (kIsWeb) {
        // Web-specific download via conditional import
        final bytes = utf8.encode(text);
        web_download.downloadFile(bytes, fileName);
      } else {
        // Native implementation: use path_provider + share_plus
        final tempDir = await getTemporaryDirectory();
        final file = io.File('${tempDir.path}/$fileName');
        await file.writeAsString(text);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'WRAPD Session: ${session.title}',
        );
      }

      return true;
    } catch (e) {
      WrapdLogger.e('Export failed', e);
      return false;
    }
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
