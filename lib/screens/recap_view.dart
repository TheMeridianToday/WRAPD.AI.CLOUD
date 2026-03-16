import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';

class RecapView extends StatelessWidget {
  final String hash;

  const RecapView({super.key, required this.hash});

  Future<Map<String, dynamic>> _fetchRecapData() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('recap_links')
        .select('*, sessions(*), action_items(*), decisions(*), open_questions(*)')
        .eq('hash', hash)
        .single();
    return response;
  }

  Future<void> _requestRenewal(BuildContext context, String sessionId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.rpc('notify_host_renewal', params: {'session_id': sessionId});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Renewal request sent to host')),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? WrapdColors.darkVoid : WrapdColors.lightCanvas,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchRecapData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: WrapdColors.cobalt));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final session = data['sessions'] as Map<String, dynamic>;
          final actionItems = List<Map<String, dynamic>>.from(data['action_items'] as Iterable<dynamic>? ?? []);
          final decisions = List<Map<String, dynamic>>.from(data['decisions'] as Iterable<dynamic>? ?? []);
          final openQuestions = List<Map<String, dynamic>>.from(data['open_questions'] as Iterable<dynamic>? ?? []);
          
          final expiresAtStr = data['expires_at'] as String?;
          final expiresAt = expiresAtStr != null ? DateTime.parse(expiresAtStr) : null;
          final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());

          if (isExpired) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'This recap has expired.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                    ),
                  ),
                  const SizedBox(height: WrapdColors.p16),
                  WrapdButton(
                    label: 'Request Renewal',
                    variant: WrapdButtonVariant.primary,
                    onPressed: () => _requestRenewal(context, session['id'] as String),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(WrapdColors.p24),
                        children: [
                          _buildHeader(theme, isDark, session, actionItems.length, decisions.length, openQuestions.length),
                          const SizedBox(height: WrapdColors.p32),
                          if (actionItems.isNotEmpty) ...[
                            _buildActions(theme, isDark, actionItems),
                            const SizedBox(height: WrapdColors.p32),
                          ],
                          if (decisions.isNotEmpty) ...[
                            _buildDecisions(theme, isDark, decisions),
                            const SizedBox(height: WrapdColors.p32),
                          ],
                          if (openQuestions.isNotEmpty) ...[
                            _buildOpenQuestions(theme, isDark, openQuestions),
                          ],
                        ],
                      ),
                    ),
                    _buildStickyFooter(theme, isDark),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, Map<String, dynamic> session, int actions, int decisions, int questions) {
    final createdAtStr = session['created_at'] as String?;
    final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy').format(createdAt);
    
    final durationSecs = session['duration_secs'] as int? ?? 0;
    final duration = Duration(seconds: durationSecs);
    final durationStr = "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s";

    final title = session['title'] as String? ?? 'Untitled Session';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineLarge?.copyWith(fontSize: 28),
        ),
        const SizedBox(height: WrapdColors.p8),
        Text(
          '$dateStr · $durationStr',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
          ),
        ),
        const SizedBox(height: WrapdColors.p4),
        Text(
          '$actions actions · $decisions decisions · $questions open questions',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme, bool isDark, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIONS',
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 10,
            letterSpacing: 2.0,
            color: WrapdColors.emerald,
          ),
        ),
        const SizedBox(height: WrapdColors.p16),
        ...items.map((item) {
          final tier = item['tier'] as String?;
          final isConfirmed = tier == 'confirmed';
          final speakerTrack = item['owner_track'] as String? ?? 'S1';
          final speakerIndex = int.tryParse(speakerTrack.replaceAll('S', '')) ?? 1;
          
          return _buildActionItem(
            theme: theme,
            isDark: isDark,
            isConfirmed: isConfirmed,
            owner: (item['owner_name'] as String?) ?? speakerTrack,
            speakerIndex: speakerIndex - 1,
            task: (item['task'] as String?) ?? '',
            deadline: (item['deadline'] as String?) ?? 'No deadline',
          );
        }),
      ],
    );
  }

  Widget _buildActionItem({
    required ThemeData theme,
    required bool isDark,
    required bool isConfirmed,
    required String owner,
    required int speakerIndex,
    required String task,
    required String deadline,
  }) {
    final content = Padding(
      padding: const EdgeInsets.only(left: WrapdColors.p12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: WrapdColors.getSpeakerColor(speakerIndex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: WrapdColors.p4),
                Expanded(
                  child: Text(
                    owner,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16)),
                const SizedBox(height: WrapdColors.p8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: WrapdColors.p8, vertical: WrapdColors.p4),
                      decoration: BoxDecoration(
                        color: WrapdColors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(WrapdColors.radiusSmall),
                      ),
                      child: Text(
                        deadline,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: WrapdColors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isConfirmed) ...[
                      const SizedBox(width: WrapdColors.p8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: WrapdColors.p8, vertical: WrapdColors.p4),
                        decoration: BoxDecoration(
                          color: WrapdColors.amber.withValues(alpha: 0.1),
                          border: Border.all(color: WrapdColors.amber, width: 1),
                          borderRadius: BorderRadius.circular(WrapdColors.radiusSmall),
                        ),
                        child: Text(
                          'Unconfirmed',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: WrapdColors.amber),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: WrapdColors.p16),
      decoration: isConfirmed 
        ? const BoxDecoration(
            border: Border(left: BorderSide(color: WrapdColors.emerald, width: 3)),
          )
        : null,
      child: isConfirmed 
        ? content 
        : CustomPaint(
            painter: _DashedLinePainter(color: WrapdColors.amber, width: 2),
            child: content,
          ),
    );
  }

  Widget _buildDecisions(ThemeData theme, bool isDark, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DECISIONS',
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 10,
            letterSpacing: 2.0,
            color: WrapdColors.cobalt,
          ),
        ),
        const SizedBox(height: WrapdColors.p16),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: WrapdColors.p12),
          padding: const EdgeInsets.only(left: WrapdColors.p12),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: WrapdColors.cobalt, width: 3)),
          ),
          child: Text(
            (item['summary'] as String?) ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
          ),
        )),
      ],
    );
  }

  Widget _buildOpenQuestions(ThemeData theme, bool isDark, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPEN QUESTIONS',
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 10,
            letterSpacing: 2.0,
            color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
          ),
        ),
        const SizedBox(height: WrapdColors.p16),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: WrapdColors.p12),
          padding: const EdgeInsets.only(left: WrapdColors.p12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted, width: 3)),
          ),
          child: Text(
            (item['question'] as String?) ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildStickyFooter(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WrapdColors.p16),
      decoration: BoxDecoration(
        color: isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder)),
      ),
      child: Column(
        children: [
          Text(
            'Engineered by WRAPD. Eliminate the work after the meeting.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: WrapdColors.cobalt,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WrapdColors.p12),
          Wrap(
            spacing: WrapdColors.p16,
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Clone this meeting structure →', style: TextStyle(color: WrapdColors.cobalt)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Join your team on WRAPD →', style: TextStyle(color: WrapdColors.cobalt)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double width;

  _DashedLinePainter({required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    var max = size.height;
    var dashHeight = 4.0;
    var dashSpace = 4.0;
    double startY = 0.0;

    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
