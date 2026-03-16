import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_model.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';

class ShareLinkButton extends StatelessWidget {
  final WrapdSession session;

  const ShareLinkButton({super.key, required this.session});

  Future<void> _handleShare(BuildContext context) async {
    if (session.status != SessionStatus.ready) return;

    try {
      final supabase = Supabase.instance.client;
      
      // Query real hash
      var response = await supabase
          .from('recap_links')
          .select('hash')
          .eq('session_id', session.id)
          .maybeSingle();

      String? hash;
      if (response == null) {
        // Call RPC to create one if null
        final newHash = await supabase.rpc('create_recap_link', params: {'session_id': session.id});
        hash = newHash as String;
      } else {
        hash = response['hash'] as String;
      }

      final link = 'https://wrapd.ai/r/$hash';
      await Clipboard.setData(ClipboardData(text: link));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recap link copied — anyone with this link can view'),
            backgroundColor: WrapdColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Derived state
    final isProcessing = session.status != SessionStatus.ready;
    final isExpired = false; // Mock for now, would check remaining allowance / TTL

    if (isProcessing) {
      return WrapdButton(
        label: 'Processing...',
        variant: WrapdButtonVariant.secondary,
        icon: Icons.hourglass_top_rounded,
        onPressed: () {},
      );
    }

    if (isExpired) {
      return WrapdButton(
        label: 'Renew Link',
        variant: WrapdButtonVariant.primary,
        icon: Icons.refresh_rounded,
        onPressed: () {
          // Upsell trigger
        },
      );
    }

    // Default "Share Recap"
    return WrapdButton(
      label: 'Share Recap',
      variant: WrapdButtonVariant.primary,
      icon: Icons.ios_share_rounded,
      onPressed: () => _handleShare(context),
    );
  }
}
