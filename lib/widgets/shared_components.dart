import 'package:flutter/material.dart';
import '../theme/wrapd_theme.dart';
import '../models/session_model.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────
//  SpeakerDot
//  12px circle representing a speaker's identity color.
//  Set showBar=true to add the 2px vertical timeline bar.
// ─────────────────────────────────────────────────────────

class SpeakerDot extends StatelessWidget {
  final int speakerIndex;
  final bool showBar;
  final double dotSize;

  const SpeakerDot({
    super.key,
    required this.speakerIndex,
    this.showBar = false,
    this.dotSize = WrapdColors.dotSizeMedium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = WrapdColors.getSpeakerColor(speakerIndex);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.cardColor,
              width: 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
        ),
        if (showBar) ...[
          const SizedBox(width: WrapdColors.p8),
          Container(
            width: 2,
            height: 24,
            color: color.withValues(alpha: 0.4),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SpeakerDotRow
//  Renders up to 5 overlapping dots representing speakers.
// ─────────────────────────────────────────────────────────

class SpeakerDotRow extends StatelessWidget {
  final int count;
  final double dotSize;
  final double overlap;

  const SpeakerDotRow({
    super.key,
    required this.count,
    this.dotSize = 14.0,
    this.overlap = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = count.clamp(0, 5);
    final theme = Theme.of(context);
    return SizedBox(
      height: dotSize,
      width: displayCount * (dotSize - overlap) + overlap,
      child: Stack(
        children: List.generate(displayCount, (i) {
          return Positioned(
            left: i * (dotSize - overlap),
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: WrapdColors.getSpeakerColor(i),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.cardColor,
                  width: 1.2,
                ),
                boxShadow: theme.brightness == Brightness.dark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TranscriptBlock
//  One spoken segment rendered with hanging-indent style.
// ─────────────────────────────────────────────────────────

class TranscriptBlock extends StatelessWidget {
  final TranscriptSegment segment;
  final VoidCallback? onTimestampTap;
  final VoidCallback? onSpeakerTap;
  final bool compact;

  const TranscriptBlock({
    super.key,
    required this.segment,
    this.onTimestampTap,
    this.onSpeakerTap,
    this.compact = false,
  });

  String _formatTimestamp(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted;
    final speakerColor =
        WrapdColors.getSpeakerColor(segment.speakerIndex);

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: compact ? WrapdColors.p8 : WrapdColors.p12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left gutter: dot + bar
          Column(
            children: [
              const SizedBox(height: 6),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: speakerColor, shape: BoxShape.circle),
              ),
              if (!compact)
                Container(
                  width: 2,
                  height: 32,
                  margin: const EdgeInsets.only(top: 4),
                  color: speakerColor.withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(width: WrapdColors.p12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meta row
                Row(
                  children: [
                    InkWell(
                      onTap: onSpeakerTap,
                      borderRadius: BorderRadius.circular(4),
                      child: Text(
                        segment.speakerName.toUpperCase(),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: speakerColor, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: WrapdColors.p8),
                    InkWell(
                      onTap: onTimestampTap,
                      borderRadius: BorderRadius.circular(WrapdColors.radiusSmall),
                      overlayColor: WidgetStateProperty.all(
                        speakerColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WrapdColors.p6,
                          vertical: WrapdColors.p3,
                        ),
                        child: Text(
                          _formatTimestamp(segment.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            decoration: onTimestampTap != null
                                ? TextDecoration.underline
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WrapdColors.p4),
                // Body text
                Text(
                  segment.text,
                  style: compact
                      ? theme.textTheme.bodyMedium
                      : theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TopicDivider
//  Horizontal rule + centered TOPIC label.
// ─────────────────────────────────────────────────────────

class TopicDivider extends StatelessWidget {
  final String label;

  const TopicDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border =
        isDark ? WrapdColors.darkBorder : WrapdColors.lightBorder;
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: WrapdColors.p16),
      child: Row(
        children: [
          Expanded(child: Divider(color: border, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: WrapdColors.p12),
            child: Text(
              'TOPIC: ${label.toUpperCase()}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark
                    ? WrapdColors.darkMuted
                    : WrapdColors.lightMuted,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: border, height: 1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  StatusPill
//  Color-coded pill label for session status.
// ─────────────────────────────────────────────────────────

class StatusPill extends StatelessWidget {
  final SessionStatus status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case SessionStatus.ready:
        bg = WrapdColors.success;
        label = 'Ready';
        break;
      case SessionStatus.processing:
        bg = WrapdColors.processing;
        label = 'Processing';
        break;
      case SessionStatus.failed:
        bg = WrapdColors.danger;
        label = 'Failed';
        break;
      case SessionStatus.draft:
        bg = WrapdColors.locked;
        label = 'Draft';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: WrapdColors.p8, vertical: WrapdColors.p4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius:
            BorderRadius.circular(WrapdColors.radiusPill),
        border: Border.all(color: bg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: bg,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SessionCard
//  Library list item. Tap navigates to Session Detail.
// ─────────────────────────────────────────────────────────

class SessionCard extends StatelessWidget {
  final WrapdSession session;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.onLongPress,
  });

  String _formatDate(DateTime dt) =>
      DateFormat('MMM d, yyyy · h:mm a').format(dt);

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Session: ${session.title}',
      button: true,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(WrapdColors.radiusHero),
          splashFactory: InkSparkle.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(
                horizontal: WrapdColors.p16,
                vertical: WrapdColors.p8),
            padding: const EdgeInsets.all(WrapdColors.p16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius:
                  BorderRadius.circular(WrapdColors.radiusHero),
              boxShadow: isDark ? [] : WrapdColors.cardShadow,
              border: Border.all(
                color: isDark
                    ? WrapdColors.darkBorder.withValues(alpha: 0.6)
                    : WrapdColors.lightBorder.withValues(alpha: 0.6),
                width: 0.6,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: title + status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: WrapdColors.p8),
                    StatusPill(status: session.status),
                  ],
                ),
                const SizedBox(height: WrapdColors.p8),
                // Meta row: date + duration
                Text(
                  '${_formatDate(session.createdAt)}  ·  ${_formatDuration(session.duration)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: WrapdColors.p12),
                // Bottom row: speaker dots
                SpeakerDotRow(count: session.speakerCount),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  WrapdButton — Primary / Secondary / Ghost / Danger
// ─────────────────────────────────────────────────────────

enum WrapdButtonVariant { primary, secondary, ghost, danger }

class WrapdButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final WrapdButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  const WrapdButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = WrapdButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case WrapdButtonVariant.primary:
        bg = WrapdColors.cobalt;
        fg = Colors.white;
        border = null;
        break;
      case WrapdButtonVariant.secondary:
        bg = Colors.transparent;
        fg = WrapdColors.cobalt;
        border = const BorderSide(color: WrapdColors.cobalt, width: 1.5);
        break;
      case WrapdButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted;
        border = null;
        break;
      case WrapdButtonVariant.danger:
        bg = WrapdColors.danger;
        fg = Colors.white;
        border = null;
        break;
    }

    final child = Row(
      mainAxisSize:
          fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: WrapdColors.p8),
        ],
        Text(label,
            style: TextStyle(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ],
    );

    return SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          overlayColor: fg.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(
              horizontal: WrapdColors.p24,
              vertical: WrapdColors.p12),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(WrapdColors.radius),
            side: border ?? BorderSide.none,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AllowanceBar
//  Shows weekly export budget (e.g. "2 / 3 this week").
// ─────────────────────────────────────────────────────────

class AllowanceBar extends StatelessWidget {
  final int used;
  final int max;

  const AllowanceBar({super.key, required this.used, required this.max});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remaining = (max - used).clamp(0, max);
    final progress = max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    if (progress >= 1.0) {
      barColor = WrapdColors.danger;
    } else if (progress >= 0.66) {
      barColor = WrapdColors.processing;
    } else {
      barColor = WrapdColors.success;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Free Export Allowance',
              style: theme.textTheme.titleSmall?.copyWith(
                  color: isDark
                      ? WrapdColors.darkMuted
                      : WrapdColors.lightMuted),
            ),
            Text(
              '$remaining / $max this week',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: barColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: WrapdColors.p8),
        ClipRRect(
          borderRadius: BorderRadius.circular(WrapdColors.radiusPill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: isDark
                ? WrapdColors.darkBorder
                : WrapdColors.lightBorder,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  EmptyState
//  Guidance for screens with no data.
// ─────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WrapdColors.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: muted.withValues(alpha: 0.4)),
            const SizedBox(height: WrapdColors.p24),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: WrapdColors.p8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: WrapdColors.p32),
              WrapdButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: WrapdButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
