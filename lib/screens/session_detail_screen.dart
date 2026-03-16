import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/audio_provider.dart';
import '../models/session_model.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';
import '../widgets/share_link_button.dart';
import '../services/logger_service.dart';
import '../services/export_service.dart';
import '../services/ai_service.dart';
import 'dart:ui';

// ─────────────────────────────────────────────────────────
//  SessionDetailScreen — Screen 3: Details & Analysis
// ─────────────────────────────────────────────────────────

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final String? initialPrompt;

  const SessionDetailScreen({
    super.key, 
    required this.sessionId,
    this.initialPrompt,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialPrompt != null ? 1 : 0;

    // Auto-load audio into AudioProvider when session has a recording
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SessionProvider>();
      final session = provider.sessions.firstWhere(
        (s) => s.id == widget.sessionId,
        orElse: () => provider.sessions.first,
      );
      if (session.hasAudio && session.audioPath != null) {
        context.read<AudioProvider>().loadAudio(session.audioPath!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<SessionProvider>();

    // Load session from provider
    final session = provider.sessions.firstWhere(
      (s) => s.id == widget.sessionId,
      orElse: () => provider.sessions.first,
    );

    return Scaffold(
      backgroundColor:
          isDark ? WrapdColors.darkCanvas : WrapdColors.lightCanvas,
      appBar: AppBar(
        title: Text(session.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showRenameDialog(context, session),
          ),
          Padding(
            padding: const EdgeInsets.only(right: WrapdColors.p8),
            child: ShareLinkButton(session: session),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Tab Navigation ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: WrapdColors.p16, vertical: WrapdColors.p8),
            child: Row(
              children: [
                _TabButton(
                  label: 'Transcript',
                  isActive: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                _TabButton(
                  label: 'Synthesis',
                  isActive: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
                _TabButton(
                  label: 'Studio',
                  isActive: _tabIndex == 2,
                  onTap: () => setState(() => _tabIndex = 2),
                ),
              ],
            ),
          ),

          // ── Active Content ─────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _TranscriptTab(session: session),
                _SynthesisTab(session: session, initialPrompt: widget.initialPrompt),
                _StudioTab(session: session),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WrapdSession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Session'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<SessionProvider>()
                  .renameSession(session.id, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _TabButton — Internal tab switcher
// ─────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? WrapdColors.cobalt
        : (isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? WrapdColors.cobalt : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _TranscriptTab
// ─────────────────────────────────────────────────────────

class _TranscriptTab extends StatelessWidget {
  final WrapdSession session;

  const _TranscriptTab({required this.session});

  @override
  Widget build(BuildContext context) {

    // Combine topics and segments into a single sorted list
    final List<dynamic> items = [...session.segments, ...session.topics];
    items.sort((a, b) {
      Duration timeA = (a is TranscriptSegment) ? a.timestamp : (a as TopicMarker).timestamp;
      Duration timeB = (b is TranscriptSegment) ? b.timestamp : (b as TopicMarker).timestamp;
      return timeA.compareTo(timeB);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(WrapdColors.p16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        if (item is TopicMarker) {
          return TopicDivider(label: item.label);
        } else {
          return TranscriptBlock(
            segment: item as TranscriptSegment,
            onTimestampTap: () {
              // Seek audio player if integrated
              WrapdLogger.i('Seeking to ${item.timestamp}');
            },
          );
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _SynthesisTab — AI Fact Analysis
// ─────────────────────────────────────────────────────────

class _SynthesisTab extends StatefulWidget {
  final WrapdSession session;
  final String? initialPrompt;

  const _SynthesisTab({required this.session, this.initialPrompt});

  @override
  State<_SynthesisTab> createState() => _SynthesisTabState();
}

class _SynthesisTabState extends State<_SynthesisTab> {
  double _splitRatio = 0.35;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isGenerating = false;
  final AIService _ai = AIService();

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendPrompt(widget.initialPrompt!);
      });
    }
  }

  void _sendChipPrompt(Stream<String> Function(WrapdSession) aiCall, String label) {
    _sendStreamingPrompt(label, aiCall(widget.session));
  }

  void _sendPrompt([String? explicitText]) {
    final text = explicitText ?? _inputController.text.trim();
    if (text.isEmpty) return;
    if (explicitText == null) _inputController.clear();
    final stream = _ai.askAboutSession(widget.session, text);
    _sendStreamingPrompt(text, stream);
  }

  void _sendStreamingPrompt(String userText, Stream<String> responseStream) {
    final provider = context.read<SessionProvider>();
    final aiMsgId = 'ai-${DateTime.now().millisecondsSinceEpoch}';

    provider.addSynthesisMessage(
      widget.session.id,
      SynthesisMessage(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        isUser: true,
        text: userText,
      ),
    );

    // Add placeholder AI message that we'll update in-place as tokens stream in
    provider.addSynthesisMessage(
      widget.session.id,
      SynthesisMessage(id: aiMsgId, isUser: false, text: ''),
    );

    setState(() => _isGenerating = true);

    final buf = StringBuffer();
    responseStream.listen(
      (token) {
        buf.write(token);
        provider.updateSynthesisMessage(
          widget.session.id,
          aiMsgId,
          buf.toString(),
        );
        _scrollToBottom();
      },
      onDone: () {
        if (mounted) setState(() => _isGenerating = false);
        _scrollToBottom();
      },
      onError: (e) {
        provider.updateSynthesisMessage(
          widget.session.id,
          aiMsgId,
          'Error: $e',
        );
        if (mounted) setState(() => _isGenerating = false);
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: WrapdColors.normal,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top Pane: Synthesis Controls ─────────────────
        Expanded(
          flex: (_splitRatio * 100).toInt(),
          child: _SynthesisHeader(
          session: widget.session,
          onChipTap: _sendChipPrompt,
        ),
        ),

        // ── Resize Handle ────────────────────────────────
        GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _splitRatio = (_splitRatio + details.delta.dy / 500).clamp(0.2, 0.7);
            });
          },
          child: Container(
            height: 24,
            width: double.infinity,
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: WrapdColors.darkBorder.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),

        // ── Bottom Pane: AI Chat ─────────────────────────
        Expanded(
          flex: ((1 - _splitRatio) * 100).toInt(),
          child: Column(
            children: [
              Expanded(
                child: _SynthesisChatList(
                  messages: widget.session.messages,
                  scrollController: _chatScrollController,
                ),
              ),
              _SynthesisInput(
                controller: _inputController,
                onSend: _sendPrompt,
                isGenerating: _isGenerating,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SynthesisHeader extends StatelessWidget {
  final WrapdSession session;
  final void Function(String label, Stream<String> Function(WrapdSession) call) onChipTap;
  const _SynthesisHeader({required this.session, required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(WrapdColors.p16),
      decoration: BoxDecoration(
        color: isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(WrapdColors.radiusHero),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: WrapdColors.cobalt, size: 20),
              const SizedBox(width: WrapdColors.p8),
              Text('Fact Engine Synthesis',
                  style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: WrapdColors.p16),
          // Horizontal actions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ActionChip(label: 'Meeting Summary', onTap: () => onChipTap('Meeting Summary', (s) => AIService().generateSummary(s))),
                _ActionChip(label: 'Action Items',    onTap: () => onChipTap('Action Items',    (s) => AIService().extractActionItems(s))),
                _ActionChip(label: 'Key Questions',   onTap: () => onChipTap('Key Questions',   (s) => AIService().extractKeyQuestions(s))),
                _ActionChip(label: 'Decisions',       onTap: () => onChipTap('Decisions',       (s) => AIService().extractDecisions(s))),
              ],
            ),
          ),
          const Spacer(),
          AllowanceBar(
            used: session.exportAllowanceUsed,
            max: session.exportAllowanceMax,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor:
            isDark ? WrapdColors.darkCanvas : WrapdColors.lightCanvas,
        side: BorderSide(
          color: isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _SynthesisChatList extends StatelessWidget {
  final List<SynthesisMessage> messages;
  final ScrollController scrollController;

  const _SynthesisChatList(
      {required this.messages, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(WrapdColors.p16),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final m = messages[i];
        return _ChatMessage(message: m);
      },
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final SynthesisMessage message;
  const _ChatMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: WrapdColors.p16),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(WrapdColors.p12),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: message.isUser
                  ? WrapdColors.cobalt
                  : (isDark
                      ? WrapdColors.darkSurface
                      : WrapdColors.lightSurface),
              borderRadius: BorderRadius.circular(WrapdColors.radius),
            ),
            child: Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: message.isUser ? Colors.white : null,
              ),
            ),
          ),
          if (message.chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                children: message.chips
                    .map((c) => _TimestampChipWidget(chip: c))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimestampChipWidget extends StatelessWidget {
  final TimestampChip chip;
  const _TimestampChipWidget({required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: WrapdColors.cobalt.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        chip.label,
        style: const TextStyle(
          fontSize: 11,
          color: WrapdColors.cobalt,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SynthesisInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isGenerating;

  const _SynthesisInput({
    required this.controller,
    required this.onSend,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? WrapdColors.darkCanvas : WrapdColors.lightCanvas,
          borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
          border: Border.all(color: isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask about session facts...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isGenerating ? null : onSend,
              icon: Icon(
                isGenerating ? Icons.hourglass_top_rounded : Icons.arrow_upward_rounded,
                color: WrapdColors.cobalt,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _StudioTab
// ─────────────────────────────────────────────────────────

class _StudioTab extends StatelessWidget {
  final WrapdSession session;
  const _StudioTab({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final audioProvider = context.watch<AudioProvider>();

    if (!session.hasAudio || session.audioPath == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(WrapdColors.p32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_off_outlined,
                  size: 56,
                  color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted),
              const SizedBox(height: WrapdColors.p16),
              Text('No audio recording',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: WrapdColors.p8),
              Text(
                'This session was transcribed without saving audio.\nStart a new recording with audio enabled.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WrapdColors.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Waveform
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(WrapdColors.p16),
            decoration: BoxDecoration(
              color: isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface,
              borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
              border: Border.all(
                color: isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder,
              ),
            ),
            child: CustomPaint(
              painter: _WaveformPainter(
                progress: audioProvider.duration.inMilliseconds > 0 
                  ? audioProvider.position.inMilliseconds / audioProvider.duration.inMilliseconds 
                  : 0.0,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: WrapdColors.p32),

          // Timer
          Center(
            child: Column(
              children: [
                Text(
                  _formatDuration(audioProvider.position),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '/ ${_formatDuration(audioProvider.duration)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WrapdColors.p48),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, size: 32),
                onPressed: () => audioProvider.skipBackward(),
              ),
              GestureDetector(
                onTap: () {
                  if (audioProvider.isPlaying) {
                    audioProvider.pause();
                  } else {
                    audioProvider.play();
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: WrapdColors.cobalt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    audioProvider.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, size: 32),
                onPressed: () => audioProvider.skipForward(),
              ),
            ],
          ),

          const SizedBox(height: WrapdColors.p48),
          
          Text('EXPORT & SHARE', style: theme.textTheme.titleSmall?.copyWith(color: WrapdColors.cobalt)),
          const SizedBox(height: WrapdColors.p16),
          
          AllowanceBar(
            used: session.exportAllowanceUsed,
            max: session.exportAllowanceMax,
          ),
          const SizedBox(height: WrapdColors.p24),
          
          ShareLinkButton(session: session),
          const SizedBox(height: WrapdColors.p12),
          
          WrapdButton(
            label: 'Export Audio (.opus)',
            variant: WrapdButtonVariant.secondary,
            icon: Icons.audio_file_outlined,
            fullWidth: true,
            onPressed: () {
              // Trigger export flow for session
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating export...')),
              );
              ExportService.exportToText(session).then((success) {
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export downloaded successfully.')),
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─────────────────────────────────────────────────────────
//  Waveform Painter (Visual placeholder)
// ─────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _WaveformPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 60;
    final barWidth = size.width / barCount;
    final playedPaint = Paint()
      ..color = WrapdColors.cobalt
      ..strokeCap = StrokeCap.round;
    final unplayedPaint = Paint()
      ..color = isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      // Generate height from a pseudo-random pattern
      final ratio = ((i * 7 + 13) % 17) / 17.0;
      final barHeight = 10 + ratio * (size.height * 0.7);
      final top = size.height / 2 - barHeight / 2;
      final bottom = size.height / 2 + barHeight / 2;

      final paint = (i / barCount < progress) ? playedPaint : unplayedPaint;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        paint..strokeWidth = barWidth * 0.55,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
