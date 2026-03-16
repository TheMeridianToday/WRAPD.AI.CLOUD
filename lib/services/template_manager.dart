import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_model.dart';

// ---------------------------------------------------------------------------
// Sealed result class — callers handle UI; TemplateManager stays UI-free
// ---------------------------------------------------------------------------

sealed class TemplateResult {
  const TemplateResult();
}

final class TemplateSuccess extends TemplateResult {
  final String code;
  const TemplateSuccess(this.code);
}

final class TemplateError extends TemplateResult {
  final String message;
  const TemplateError(this.message);
}

// ─────────────────────────────────────────────────────────
//  TemplateManager (Agent 2)
//  Handles generation and import of template codes via Supabase
// ─────────────────────────────────────────────────────────

class TemplateManager {
  /// GENERATE flow: Returns TemplateResult — no BuildContext.
  /// Caller is responsible for showing the bottom sheet / snackbar.
  static Future<TemplateResult> generateTemplate(WrapdSession session, String title) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        return const TemplateError('You need to sign in before creating templates.');
      }

      final response = await client.rpc('generate_template_code');
      final code = (response as String).trim();
      final templateName = title.trim().isEmpty ? session.title : title.trim();

      await client.from('templates').insert({
        'code': code,
        'creator_id': user.id,
        'source_session_id': session.id,
        'name': templateName,
        'extraction_rules': {
          'prompts': <String>[],
        },
        'recap_structure': {
          'order': 'actions_first',
        },
        'speaker_personas': <Map<String, dynamic>>[],
        'is_public': false,
      });

      return TemplateSuccess(code);
    } catch (e) {
      return TemplateError('Failed to generate template: $e');
    }
  }

  /// IMPORT flow: Returns TemplateResult — no BuildContext.
  /// Caller is responsible for showing success/error snackbars.
  static Future<TemplateResult> importTemplate(String code) async {
    try {
      final trimmedCode = code.trim().toUpperCase();
      if (trimmedCode.isEmpty) {
        return const TemplateError('Template code cannot be empty.');
      }

      final client = Supabase.instance.client;
      await client
          .from('templates')
          .select()
          .eq('code', trimmedCode)
          .eq('is_public', true)
          .single();

      await client.rpc(
        'increment_template_use',
        params: {'p_code': trimmedCode},
      );

      return TemplateSuccess(trimmedCode);
    } catch (e) {
      return TemplateError('Code not found. Check with the person who shared it.');
    }
  }

}
