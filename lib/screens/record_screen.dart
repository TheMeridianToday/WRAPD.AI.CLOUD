import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/session_provider.dart';
import '../providers/recording_provider.dart';
import '../models/session_model.dart';
import '../services/audio_service.dart';
import '../config/wrapd_config.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';
import 'session_detail_screen.dart';
import 'dart:async';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import '../services/ai_service.dart';

// ─────────────────────────────────────────────────────────
//  RecordScreen — Screen 2: Live Recording (Focus Mode)
// ─────────────────────────────────────────────────────────

enum RecordScreenState { permission, ready, recording, stopped }

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  RecordScreenState _screenState = RecordScreenState.permission;
  bool _showLiveAI = false;
  // User choice: show live transcript or keep private (audio only)
  bool _showLiveTranscript = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<TopicMarker> _topics = [];
  final List<SynthesisMessage> _liveAiMessages = [];

  // Map to track renamed speakers during the session
  final Map<int, String> _speakerNames = {
    0: 'Alex',
    1: 'Jordan',
    2: 'Sam',
  };

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _liveAiMessages.add(const SynthesisMessage(
      id: 'ai-init',
      isUser: false,
      text: 'I am monitoring the session. Ask me facts about the current discussion.',
    ));

    _checkPermission();
  }

  Future<void> _checkPermission() async {
    // On web, permission_handler doesn't work.
    // The browser asks for mic access when speech_to_text starts.
    // Skip straight to ready so the UI doesn't get stuck.
    if (kIsWeb) {
      setState(() => _screenState = RecordScreenState.ready);
      return;
    }
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      setState(() => _screenState = RecordScreenState.ready);
    } else {
      final result = await Permission.microphone.request();
      if (result.isGranted) {
        setState(() => _screenState = RecordScreenState.ready);
      }
      // If denied, stay on permission screen with Grant Access button
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _startRecording() async {
    HapticFeedback.heavyImpact();
    final provider = context.read<RecordingProvider>();
    final started = await provider.start();
    if (!mounted) return;
    if (started) {
      setState(() => _screenState = RecordScreenState.recording);
      return;
    }
    setState(() => _screenState = RecordScreenState.ready);
    final err = provider.lastError.isNotEmpty
        ? provider.lastError
        : 'Could not start. Check microphone permission.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  void _renameSpeaker(int index) {
    final controller = TextEditingController(text: _speakerNames[index]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Identify Speaker ${index + 1}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter name...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _speakerNames[index] = controller.text;
                });
                context.read<RecordingProvider>().setSpeakerName(index, controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addNotation() {
    final elapsed = context.read<RecordingProvider>().duration;
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) {
        String label = '';
        return AlertDialog(
          title: const Text('Add Notation / Header'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Header title...'),
            onChanged: (v) => label = v,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (label.isNotEmpty) {
                  setState(() {
                    _topics.add(TopicMarker(
                      id: const Uuid().v4(),
                      label: label,
                      timestamp: elapsed,
                      isUserNote: true,
                    ));
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _onStopTap() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text(
            'The recording will be stopped and saved to your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: WrapdColors.danger),
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx);
              _confirmStop();
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmStop() async {
    final recordingProvider = context.read<RecordingProvider>();
    final sessionProvider = context.read<SessionProvider>();
    
    final path = await recordingProvider.stop();
    final sessionId = const Uuid().v4();
    final now = DateTime.now();

    final newSession = WrapdSession(
      id: sessionId,
      title: 'Session ${now.month}-${now.day}-${now.year}',
      createdAt: now,
      duration: recordingProvider.duration,
      status: SessionStatus.ready,
      segments: recordingProvider.segments,
      topics: _topics,
      hasAudio: path != null,
      audioPath: path,
      speakerCount: recordingProvider.segments
          .map((s) => s.speakerIndex)
          .toSet()
          .length
          .clamp(1, 6),
    );

    sessionProvider.stopRecording(newSession);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => SessionDetailScreen(sessionId: sessionId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface =
        isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface;
    final recordingProvider = context.watch<RecordingProvider>();
    final isPaused = recordingProvider.isPaused;

    // Handle back button
    return PopScope(
      canPop: _screenState != RecordScreenState.recording,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stop recording before leaving.')),
          );
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? WrapdColors.darkCanvas : WrapdColors.lightCanvas,
        body: _buildBody(theme, isDark, surface, recordingProvider, isPaused),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark, Color surface, RecordingProvider recordingProvider, bool isPaused) {
    if (_screenState == RecordScreenState.permission) {
      return EmptyState(
        icon: Icons.mic_off_rounded,
        title: 'Microphone Required',
        message: 'WRAPD needs microphone access to transcribe your sessions.',
        actionLabel: 'Grant Access',
        onAction: _checkPermission,
      );
    }

    if (_screenState == RecordScreenState.ready) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(WrapdColors.p32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: WrapdColors.cobalt.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, size: 80, color: WrapdColors.cobalt),
              ),
              const SizedBox(height: 48),
              Text('Ready to Record', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'Choose how to capture this session.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Live transcript toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: WrapdColors.p16, vertical: WrapdColors.p12),
                decoration: BoxDecoration(
                  color: isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface,
                  borderRadius: BorderRadius.circular(WrapdColors.radius),
                  border: Border.all(
                    color: isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showLiveTranscript
                          ? Icons.subtitles_rounded
                          : Icons.subtitles_off_outlined,
                      color: _showLiveTranscript
                          ? WrapdColors.emerald
                          : (isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted),
                      size: 22,
                    ),
                    const SizedBox(width: WrapdColors.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Transcript',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _showLiveTranscript
                                ? 'Words appear as you speak'
                                : 'Audio recorded only — transcript after',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _showLiveTranscript,
                      onChanged: (v) => setState(() => _showLiveTranscript = v),
                      activeColor: WrapdColors.emerald,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              WrapdButton(
                label: 'Start Session',
                onPressed: _startRecording,
                variant: WrapdButtonVariant.primary,
                height: 56,
              ),
            ],
          ),
        ),
      );
    }

    // Auto-scroll logic for recording state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: WrapdColors.normal,
          curve: Curves.easeOut,
        );
      }
    });

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              // ── Header ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: WrapdColors.p24, vertical: WrapdColors.p16),
                child: Row(
                  children: [
                    // Live indicator
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Opacity(
                        opacity: isPaused ? 0.4 : _pulseAnim.value,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: WrapdColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: WrapdColors.p8),
                    Text(
                      isPaused ? 'PAUSED' : 'RECORDING',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isPaused
                            ? WrapdColors.locked
                            : WrapdColors.danger,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.auto_awesome_outlined, 
                        color: _showLiveAI ? WrapdColors.cobalt : null),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showLiveAI = !_showLiveAI);
                      },
                    ),
                    const SizedBox(width: WrapdColors.p8),
                    // Timer
                    Text(
                      _formatElapsed(recordingProvider.duration),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? WrapdColors.darkText
                            : WrapdColors.lightText,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Waveform ─────────────────────────────
              if (recordingProvider.waveform.isNotEmpty)
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _LiveWaveform(data: recordingProvider.waveform, isDark: isDark),
                ),

              // ── Live Transcript ─────────────────────────────
              Expanded(
                child: !_showLiveTranscript
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 40,
                              color: isDark
                                  ? WrapdColors.darkMuted
                                  : WrapdColors.lightMuted,
                            ),
                            const SizedBox(height: WrapdColors.p12),
                            Text(
                              'Audio only mode',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? WrapdColors.darkMuted
                                    : WrapdColors.lightMuted,
                              ),
                            ),
                            Text(
                              'Transcript generated after session ends.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? WrapdColors.darkMuted
                                    : WrapdColors.lightMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : recordingProvider.segments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 48,
                                  color: isDark
                                      ? WrapdColors.darkMuted
                                      : WrapdColors.lightMuted,
                                ),
                                const SizedBox(height: WrapdColors.p12),
                                Text(
                                  'Listening...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? WrapdColors.darkMuted
                                        : WrapdColors.lightMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                            itemCount: recordingProvider.segments.length,
                            itemBuilder: (_, i) {
                              final seg = recordingProvider.segments[i];
                              return TranscriptBlock(
                                segment: seg,
                                onSpeakerTap: () =>
                                    _renameSpeaker(seg.speakerIndex),
                              );
                            },
                          ),
              ),

                // ── Controls Bottom Sheet ────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: WrapdColors.p24,
                      vertical: WrapdColors.p12),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? WrapdColors.darkBorder
                            : WrapdColors.lightBorder,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Speaker Selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(WrapdConfig.maxSpeakers, (idx) {
                            final isSelected = recordingProvider.segments.isNotEmpty && 
                                recordingProvider.segments.last.speakerIndex == idx;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                recordingProvider.setSpeakerIndex(idx);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? WrapdColors.getSpeakerColor(idx).withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(WrapdColors.radiusPill),
                                  border: Border.all(
                                    color: isSelected 
                                        ? WrapdColors.getSpeakerColor(idx)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: WrapdColors.getSpeakerColor(idx),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _speakerNames[idx] ?? 'Speaker ${idx + 1}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? WrapdColors.getSpeakerColor(idx) : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Notation button
                          WrapdButton(
                            label: 'Notation',
                            variant: WrapdButtonVariant.secondary,
                            icon: Icons.edit_note_rounded,
                            onPressed: _addNotation,
                          ),

                          // STOP button (center, hero)
                          GestureDetector(
                            onTap: _onStopTap,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: WrapdColors.danger,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: WrapdColors.danger.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.stop_rounded,
                                    color: Colors.white, size: 32),
                              ),
                            ),
                          ),

                          // Pause button
                          WrapdButton(
                            label: isPaused ? 'Resume' : 'Pause',
                            variant: WrapdButtonVariant.ghost,
                            icon: isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              if (isPaused) {
                                recordingProvider.resume();
                              } else {
                                recordingProvider.pause();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          // ── Live AI Overlay ─────────────────────────────
          if (_showLiveAI)
            Positioned(
              top: 80,
              right: 16,
              bottom: 140,
              width: 300,
              child: _LiveAIChat(
                messages: _liveAiMessages,
                onClose: () => setState(() => _showLiveAI = false),
                onSend: (text) async {
                  HapticFeedback.lightImpact();
                  final userMsg = SynthesisMessage(id: 'u-${DateTime.now().millisecondsSinceEpoch}', isUser: true, text: text);
                  setState(() => _liveAiMessages.add(userMsg));
                  final segments = context.read<RecordingProvider>().segments;
                  final reply = await AIService().liveFactCheck(segments, text);
                  if (mounted) {
                    setState(() {
                      _liveAiMessages.add(SynthesisMessage(
                        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
                        isUser: false,
                        text: reply,
                      ));
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveWaveform extends StatelessWidget {
  final List<double> data;
  final bool isDark;

  const _LiveWaveform({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LiveWaveformPainter(data: data, isDark: isDark),
      child: const SizedBox.expand(),
    );
  }
}

class _LiveWaveformPainter extends CustomPainter {
  final List<double> data;
  final bool isDark;

  _LiveWaveformPainter({required this.data, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = WrapdColors.cobalt
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / 20;
    for (int i = 0; i < data.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final h = (data[i] * size.height).clamp(4.0, size.height);
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LiveWaveformPainter old) => old.data != data;
}

class _LiveAIChat extends StatelessWidget {
  final List<SynthesisMessage> messages;
  final VoidCallback onClose;
  final Function(String) onSend;

  const _LiveAIChat({
    required this.messages,
    required this.onClose,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? WrapdColors.darkElevated : Colors.white,
        borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
        boxShadow: WrapdColors.heroShadow,
        border: Border.all(color: WrapdColors.cobalt.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: WrapdColors.cobalt.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(WrapdColors.radiusHero)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: WrapdColors.cobalt),
                const SizedBox(width: 8),
                const Text('Live AI Fact Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onClose),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final m = messages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: m.isUser ? WrapdColors.cobalt : (isDark ? WrapdColors.darkSurface : WrapdColors.lightCanvas),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(fontSize: 12, color: m.isUser ? Colors.white : null),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask a fact...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (v) {
                      if (v.isNotEmpty) {
                        onSend(v);
                        controller.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
