import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../theme/wrapd_theme.dart';
import '../services/logger_service.dart';
import '../services/transcription_service.dart';
import 'speaker_management_screen.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────
//  SettingsScreen — System Configuration / Screen 5
// ─────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoadingInvites = true;
  final Map<String, bool> _resendingMap = {};

  @override
  void initState() {
    super.initState();
    _fetchPendingInvites();
  }

  Future<void> _fetchPendingInvites() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('invite_queue')
          .select()
          .eq('inviter_id', user.id)
          .eq('status', 'sent');

      if (mounted) {
        setState(() {
          _pendingInvites = List<Map<String, dynamic>>.from(response);
          _isLoadingInvites = false;
        });
      }
    } catch (e) {
      WrapdLogger.e('Error fetching invites: $e');
      if (mounted) {
        setState(() => _isLoadingInvites = false);
      }
    }
  }

  Future<void> _resendInvite(String inviteId) async {
    setState(() => _resendingMap[inviteId] = true);

    try {
      final supabase = Supabase.instance.client;
      // Update row status → 'pending' to re-trigger the webhook
      await supabase
          .from('invite_queue')
          .update({'status': 'pending', 'sent_at': null})
          .eq('id', inviteId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite resend triggered')),
        );
        // Refresh list
        await _fetchPendingInvites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resending: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _resendingMap.remove(inviteId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final sessionProvider = context.watch<SessionProvider>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverAppBar(
          floating: true,
          title: Text('Settings'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(WrapdColors.p16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Account Section ────────────────────────
              const _SectionHeader(label: 'ACCOUNT'),
              _SettingsRow(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                trailing: Text(sessionProvider.userName,
                    style: theme.textTheme.bodySmall),
                onTap: () => _showNameEditDialog(context, sessionProvider),
              ),
              _SettingsRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Subscription Plan',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: WrapdColors.p8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (sessionProvider.isPro ? WrapdColors.success : WrapdColors.cobalt).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                        WrapdColors.radiusPill),
                  ),
                  child: Text(
                    sessionProvider.isPro ? 'Pro' : 'Free',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sessionProvider.isPro ? WrapdColors.success : WrapdColors.cobalt,
                    ),
                  ),
                ),
                onTap: () {
                  // Upgrade sheet
                },
              ),

              const SizedBox(height: WrapdColors.p24),

              // ── Pending Invitations Section ────────────────────────
              const _SectionHeader(label: 'PENDING INVITATIONS'),
              if (_isLoadingInvites)
                const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              else if (_pendingInvites.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No pending invites', style: theme.textTheme.bodySmall),
                )
              else
                ..._pendingInvites.map((invite) {
                  final id = invite['id'].toString();
                  final isResending = _resendingMap[id] ?? false;
                  final sentAtStr = invite['sent_at'] as String?;
                  return _SettingsRow(
                    icon: Icons.mail_outline_rounded,
                    label: (invite['invitee_email'] as String?) ?? 'Unknown',
                    subtitle: 'Sent: ${sentAtStr != null ? DateFormat('MMM dd').format(DateTime.parse(sentAtStr)) : 'Pending'}',
                    trailing: isResending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: () => _resendInvite(id),
                          child: const Text('Resend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    onTap: null,
                  );
                }),

              const SizedBox(height: WrapdColors.p24),

              // ── Preferences Section ────────────────────
              const _SectionHeader(label: 'PREFERENCES'),
              _SettingsSwitchRow(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Appearance',
                value: themeProvider.isDark,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  themeProvider.toggle();
                },
              ),
              _SettingsRow(
                icon: Icons.language_rounded,
                label: 'Recording Language',
                trailing: Text(
                  TranscriptionService.supportedLanguages[sessionProvider.selectedLanguage] ?? 'English (US)',
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () => _showLanguagePicker(context, sessionProvider),
              ),
              _SettingsRow(
                icon: Icons.record_voice_over_outlined,
                label: 'Manage Speaker Profiles',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SpeakerManagementScreen()),
                  );
                },
              ),

              const SizedBox(height: WrapdColors.p24),

              // ── Transcription Section ──────────────────
              const _SectionHeader(label: 'TRANSCRIPTION'),
              _SettingsSwitchRow(
                icon: Icons.record_voice_over_outlined,
                label: 'Speaker Identification',
                value: sessionProvider.speakerIdEnabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  sessionProvider.setSpeakerIdEnabled(v);
                  WrapdLogger.i('Speaker ID toggled: $v');
                },
              ),
              _SettingsSwitchRow(
                icon: Icons.auto_fix_high_rounded,
                label: 'Auto-Punctuation',
                value: sessionProvider.autoPunctuationEnabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  sessionProvider.setAutoPunctuationEnabled(v);
                  WrapdLogger.i('Auto-punctuation toggled: $v');
                },
              ),

              const SizedBox(height: WrapdColors.p24),

              // ── About Section ──────────────────────────
              const _SectionHeader(label: 'SUPPORT & ABOUT'),
              _SettingsRow(
                icon: Icons.help_outline_rounded,
                label: 'Help & FAQ',
                onTap: () => _showHelpDialog(context),
              ),
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                label: 'Version',
                trailing: const Text('1.0.0 (Build 2026)',
                    style: TextStyle(fontSize: 13)),
                onTap: () {
                  WrapdLogger.i('Version info tapped');
                },
              ),
              _SettingsRow(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                onTap: () => _showTermsDialog(context),
              ),

              const SizedBox(height: WrapdColors.p48),
            ]),
          ),
        ),
      ],
    );
  }

  void _showNameEditDialog(BuildContext context, SessionProvider provider) {
    final controller = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Profile Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.setUserName(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SessionProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? WrapdColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(WrapdColors.radiusHero)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select Language', style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: TranscriptionService.supportedLanguages.entries.map((e) {
                    final isSelected = provider.selectedLanguage == e.key;
                    return ListTile(
                      title: Text(e.value),
                      trailing: isSelected ? const Icon(Icons.check, color: WrapdColors.cobalt) : null,
                      onTap: () {
                        provider.setLanguage(e.key);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How do I record?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Go to Home, tap "New Recording", and grant microphone access.'),
              SizedBox(height: 16),
              Text('What is Synthesis?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('It uses AI to extract facts, decisions, and thesis points from your transcript.'),
              SizedBox(height: 16),
              Text('Is my data secure?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Yes, WRAPD is offline-first. Your recordings stay on your device.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text('By using WRAPD, you agree to keep your recordings private and use the AI synthesis ethically. We do not store your audio on our servers unless you explicitly upload it for cloud processing.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('I Agree')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
          bottom: WrapdColors.p8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.black87),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodySmall) : null,
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.black87),
          const SizedBox(width: WrapdColors.p16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: WrapdColors.cobalt,
            activeTrackColor: WrapdColors.cobalt.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

