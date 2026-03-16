import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';
import 'session_detail_screen.dart';
import 'record_screen.dart';
import 'settings_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../services/logger_service.dart';
import '../models/session_model.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────
//  CommandCenterScreen — Home / Screen 1
// ─────────────────────────────────────────────────────────

class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key});

  String _greeting(String userName) {
    final hour = DateTime.now().hour;
    String g;
    if (hour < 12) g = 'Good Morning';
    else if (hour < 17) g = 'Good Afternoon';
    else g = 'Good Evening';
    return '$g, $userName';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<SessionProvider>();
    return SafeArea(
      top: false, // SliverAppBar handles top spacing
      child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // ── App Bar ──────────────────────────────────────
        SliverAppBar(
          floating: true,
          backgroundColor:
              isDark ? WrapdColors.darkCanvas : WrapdColors.lightCanvas,
          surfaceTintColor: Colors.transparent,
          titleSpacing: WrapdColors.p16,
          title: Text(
            _greeting(provider.userName),
            style: theme.textTheme.headlineMedium,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),

        // ── Quick Actions ────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                WrapdColors.p16, WrapdColors.p16, WrapdColors.p16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search meetings or facts...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                  onChanged: (v) => provider.setSearchQuery(v),
                ),
                const SizedBox(height: WrapdColors.p24),
                Text(
                  'QUICK ACTIONS',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color:
                        isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                  ),
                ),
                const SizedBox(height: WrapdColors.p12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _QuickActionCard(
                        label: 'Live Recording',
                        icon: Icons.mic_rounded,
                        isPrimary: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RecordScreen()),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _QuickActionCard(
                        label: 'Import File',
                        icon: Icons.upload_file_outlined,
                        isPrimary: false,
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.audio,
                          );
                          if (result != null) {
                            final fileName = result.files.single.name;
                            WrapdLogger.i('Processing import: $fileName');
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Processing "$fileName"...')),
                            );

                            // Simulate high-speed transcription processing
                            Future.delayed(const Duration(seconds: 2), () {
                              final now = DateTime.now();
                              final importedSession = WrapdSession(
                                id: const Uuid().v4(),
                                title: 'Import: ${fileName.split('.').first}',
                                createdAt: now,
                                duration: const Duration(minutes: 12, seconds: 45),
                                status: SessionStatus.ready,
                                segments: [
                                  TranscriptSegment(
                                    id: 'seg-1',
                                    speakerIndex: 0,
                                    speakerName: 'Speaker 1',
                                    timestamp: Duration.zero,
                                    text: 'This is an imported transcript from $fileName.',
                                  ),
                                  const TranscriptSegment(
                                    id: 'seg-2',
                                    speakerIndex: 1,
                                    speakerName: 'Speaker 2',
                                    timestamp: Duration(seconds: 30),
                                    text: 'The AI Fact Engine has successfully processed the historical audio data.',
                                  ),
                                ],
                                topics: [
                                  const TopicMarker(id: 't1', label: 'Imported Data', timestamp: Duration.zero),
                                ],
                                speakerCount: 2,
                              );

                              provider.addSession(importedSession);
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Imported "$fileName" successfully.')),
                                );
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WrapdColors.p8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: WrapdColors.p16,
                    vertical: WrapdColors.p12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? WrapdColors.cobalt.withValues(alpha: 0.1)
                        : WrapdColors.cobalt.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(WrapdColors.radius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 16,
                        color: WrapdColors.cobalt.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: WrapdColors.p8),
                      Expanded(
                        child: Text(
                          'AI-powered transcription with speaker diarization',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: WrapdColors.cobalt.withValues(alpha: 0.2),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Use a SliverList for the dynamic session data
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final session = provider.filteredSessions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: WrapdColors.p16, vertical: WrapdColors.p8),
                child: SessionCard(
                  session: session,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionDetailScreen(sessionId: session.id),
                      ),
                    );
                  },
                ),
              );
            },
            childCount: provider.filteredSessions.length,
          ),
        ),

        const SliverToBoxAdapter(
            child: SizedBox(height: WrapdColors.p48)),
      ],
    ),
  ); // SafeArea
  }
}

// ─────────────────────────────────────────────────────────
//  _QuickActionCard — Internal widget
// ─────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fg = isPrimary
        ? Colors.white
        : isDark
            ? WrapdColors.darkText
            : WrapdColors.lightText;
    
    final borderColor = isPrimary
        ? Colors.transparent
        : isDark
            ? WrapdColors.darkBorder.withValues(alpha: 0.8)
            : WrapdColors.lightBorder.withValues(alpha: 0.8);
    return Semantics(
      label: 'Action: $label',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WrapdColors.radius),
            gradient: isPrimary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WrapdColors.cobalt,
                      WrapdColors.cobalt.withValues(alpha: 0.2),
                    ],
                  )
                : null,
          ),
          child: InkWell(
            splashFactory: InkSparkle.splashFactory,
            onTap: onTap,
            borderRadius: BorderRadius.circular(WrapdColors.radius),
            overlayColor: WidgetStateProperty.all(
              fg.withValues(alpha: isPrimary ? 0.3 : 0.08),
            ),
            child: Container(
              height: 84,
              padding: const EdgeInsets.symmetric(
                horizontal: WrapdColors.p20,
                vertical: WrapdColors.p16,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(WrapdColors.radius),
                border: Border.all(
                  color: borderColor,
                  width: 0.8,
                ),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: WrapdColors.cobalt.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(WrapdColors.p8),
                    decoration: BoxDecoration(
                      color: isPrimary 
                          ? Colors.white.withValues(alpha: 0.2)
                          : fg.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(WrapdColors.radiusSmall),
                    ),
                    child: Icon(
                      icon, 
                      color: fg, 
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: WrapdColors.p8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPrimary) ...[
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
