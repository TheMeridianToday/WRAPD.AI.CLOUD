import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/session_model.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';
import 'session_detail_screen.dart';

// ─────────────────────────────────────────────────────────
//  InsightsScreen — Fact Dashboard / Screen 4
// ─────────────────────────────────────────────────────────

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<SessionProvider>();
    final readySessions = provider.readySessions;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverAppBar(
          floating: true,
          pinned: true,
          title: Text('Fact Dashboard'),
        ),
        
        // ── Fact Extraction Presets ─────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(WrapdColors.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXTRACTION PRESETS',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                  ),
                ),
                const SizedBox(height: WrapdColors.p12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PresetChip(
                        label: 'Combined Minutes',
                        icon: Icons.timer_outlined,
                        onTap: () => _handlePreset(context, provider, 'Combined Minutes'),
                      ),
                      const SizedBox(width: 8),
                      _PresetChip(
                        label: 'Speaker Thesis',
                        icon: Icons.history_edu_outlined,
                        onTap: () => _handlePreset(context, provider, 'Speaker Thesis'),
                      ),
                      const SizedBox(width: 8),
                      _PresetChip(
                        label: 'Tone Analysis',
                        icon: Icons.toll_outlined,
                        onTap: () => _handlePreset(context, provider, 'Tone Analysis'),
                      ),
                      const SizedBox(width: 8),
                      _PresetChip(
                        label: 'Financial Mentions',
                        icon: Icons.payments_outlined,
                        onTap: () => _handlePreset(context, provider, 'Financial Mentions'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (readySessions.isEmpty)
          const SliverFillRemaining(
            child: EmptyState(
              icon: Icons.insights_outlined,
              title: 'No insights available',
              message: 'Record and process a meeting to see fact-based analysis here.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: WrapdColors.p16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final session = readySessions[readySessions.length - 1 - i];
                  return _FactQueryCard(
                    session: session,
                    onExtract: (preset) {
                      provider.setActiveSession(session.id);
                      
                      // Add extraction request to history
                      provider.addSynthesisMessage(
                        session.id,
                        SynthesisMessage(
                          id: 'preset-${DateTime.now().millisecondsSinceEpoch}',
                          isUser: true,
                          text: 'Extract: $preset',
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SessionDetailScreen(sessionId: session.id, initialPrompt: preset),
                        ),
                      );
                    },
                  );
                },
                childCount: readySessions.length,
              ),
            ),
          ),

        const SliverPadding(
            padding: EdgeInsets.only(bottom: WrapdColors.p48)),
      ],
    );
  }

  void _handlePreset(BuildContext context, SessionProvider provider, String preset) {
    if (provider.readySessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sessions available to analyze.')),
      );
      return;
    }

    final session = provider.readySessions.last;
    provider.setActiveSession(session.id);
    provider.addSynthesisMessage(
      session.id,
      SynthesisMessage(
        id: 'preset-${DateTime.now().millisecondsSinceEpoch}',
        isUser: true,
        text: 'Apply Preset: $preset',
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(sessionId: session.id, initialPrompt: preset),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WrapdColors.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? WrapdColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(WrapdColors.radiusPill),
            border: Border.all(color: isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder),
            boxShadow: isDark ? [] : WrapdColors.cardShadow,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: WrapdColors.cobalt),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactQueryCard extends StatelessWidget {
  final WrapdSession session;
  final Function(String) onExtract;

  const _FactQueryCard({
    required this.session,
    required this.onExtract,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: WrapdColors.p12),
      decoration: BoxDecoration(
        color: isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface,
        borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
        border: isDark
            ? Border.all(color: WrapdColors.darkBorder, width: 0.5)
            : null,
        boxShadow: isDark ? [] : WrapdColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(session.title, style: theme.textTheme.titleMedium),
            subtitle: Text('${session.segments.length} segments · ${session.duration.inMinutes}m',
              style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onExtract('Tell me the facts about this meeting'),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniAction(label: 'Speaker Tone', icon: Icons.mood, onTap: () => onExtract('What was the tone of each speaker?')),
                _MiniAction(label: 'Key Thesis', icon: Icons.lightbulb_outline, onTap: () => onExtract('What was the main thesis of the ambassador?')),
                _MiniAction(label: 'Decisions', icon: Icons.gavel, onTap: () => onExtract('List all final decisions made.')),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: WrapdColors.cobalt.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: WrapdColors.cobalt),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WrapdColors.cobalt)),
          ],
        ),
      ),
    );
  }
}
