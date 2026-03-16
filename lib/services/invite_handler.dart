import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────
//  InviteHandler
//  Handles deep links like wrapd.ai/join?invite=[id]
// ─────────────────────────────────────────────────────────

class InviteHandler {
  static String? _pendingInviteId;
  static GoRouter? _router;

  /// Called from main.dart immediately after the router is created.
  static void setRouter(GoRouter router) {
    _router = router;
  }

  /// Call this when the app receives a deep link.
  static void handleDeepLink(Uri uri) {
    if (uri.path == '/join' && uri.queryParameters.containsKey('invite')) {
      _pendingInviteId = uri.queryParameters['invite'];
      _routeToRegistration();
    }
  }

  static Future<void> _routeToRegistration() async {
    if (_pendingInviteId == null) return;

    try {
      final supabase = Supabase.instance.client;
      final invite = await supabase
          .from('invite_queue')
          .select('invitee_email')
          .eq('id', _pendingInviteId!)
          .single();

      final email = invite['invitee_email'] as String? ?? '';
      debugPrint('Invite resolved — routing to /register for: $email');

      _router?.go('/register', extra: {'email': email});
    } catch (e) {
      debugPrint('Failed to resolve invite $_pendingInviteId: $e');
      // Route to register without email prefill — better than silent failure
      _router?.go('/register', extra: {'email': ''});
    }
  }

  /// Call after successful registration to clear pending state.
  /// The DB trigger `trg_auto_accept_invites` handles auto-accepting the invite.
  static Future<void> onRegistrationComplete() async {
    _pendingInviteId = null;
  }
}
