import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────
//  HistoryService (Agent 2)
//  Handles Day 1 Personal History logic
// ─────────────────────────────────────────────────────────

class HistoryService {
  HistoryService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static Future<bool> checkInitialHistory() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user?.userMetadata?['has_history'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getDayOneHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return _fallback;

      // ✅ Read email_hash written to raw_user_meta_data at signup (DB trigger)
      // Coordinate with DB team: confirm trigger writes email_hash on auth.users insert.
      final emailHash = user.userMetadata?['email_hash'] as String?;
      if (emailHash == null || emailHash.isEmpty) {
        debugPrint('[HistoryService] email_hash missing from user metadata — '
            'confirm DB trigger writes it at signup.');
        return _fallback;
      }

      // ✅ Real query against personal_action_history view
      final rows = await _supabase
          .from('personal_action_history')
          .select()
          .eq('owner_email_hash', emailHash)
          .limit(5);

      return {
        'count': rows.length,
        'meetingCount': rows.length,
        'recentActions': rows,
      };
    } catch (e) {
      debugPrint('[HistoryService] getDayOneHistory error: $e');
      return _fallback; // existing correct fallback — preserved
    }
  }

  // Existing error fallback — correct, preserved as-is
  static const Map<String, dynamic> _fallback = {
    'count': 0,
    'meetingCount': 0,
    'recentActions': <Map<String, dynamic>>[],
  };
}
