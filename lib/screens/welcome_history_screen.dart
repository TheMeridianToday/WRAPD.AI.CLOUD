import 'package:flutter/material.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';
import '../services/history_service.dart';
import 'library_screen.dart';

class WelcomeHistoryScreen extends StatefulWidget {
  const WelcomeHistoryScreen({super.key});

  @override
  State<WelcomeHistoryScreen> createState() => _WelcomeHistoryScreenState();
}

class _WelcomeHistoryScreenState extends State<WelcomeHistoryScreen> {
  bool _isLoading = true;
  int _actionCount = 0;
  int _meetingCount = 0;
  List<Map<String, dynamic>> _recentActions = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final historyService = HistoryService();
    final history = await historyService.getDayOneHistory();
    if (mounted) {
      setState(() {
        _actionCount = (history['count'] as num?)?.toInt() ?? 0;
        _meetingCount = (history['meetingCount'] as num?)?.toInt() ?? 0;
        _recentActions = List<Map<String, dynamic>>.from(history['recentActions'] as Iterable<dynamic>? ?? []);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? WrapdColors.darkVoid : WrapdColors.lightCanvas,
        body: const Center(
          child: CircularProgressIndicator(color: WrapdColors.cobalt),
        ),
      );
    }

    if (_actionCount == 0) {
      // Standard onboarding if no history
      return Scaffold(
        backgroundColor: isDark ? WrapdColors.darkVoid : WrapdColors.lightCanvas,
        body: Center(
          child: Text('Welcome to WRAPD', style: theme.textTheme.headlineLarge),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? WrapdColors.darkVoid : WrapdColors.lightCanvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WrapdColors.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to WRAPD',
                style: theme.textTheme.headlineLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: WrapdColors.p16),
              Text(
                'You have $_actionCount actions from $_meetingCount meetings waiting for you.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: WrapdColors.emerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WrapdColors.p32),
              Expanded(
                child: ListView.builder(
                  itemCount: _recentActions.length,
                  itemBuilder: (context, index) {
                    final action = _recentActions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: WrapdColors.p16),
                      padding: const EdgeInsets.all(WrapdColors.p16),
                      decoration: BoxDecoration(
                        color: isDark ? WrapdColors.darkSurface : WrapdColors.lightSurface,
                        borderRadius: BorderRadius.circular(WrapdColors.radius),
                        border: Border(
                          left: BorderSide(color: WrapdColors.emerald, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(action['task']?.toString() ?? '', style: theme.textTheme.titleMedium),
                          const SizedBox(height: WrapdColors.p8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(action['session_title']?.toString() ?? '', style: theme.textTheme.bodySmall),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: WrapdColors.p8, vertical: WrapdColors.p4),
                                decoration: BoxDecoration(
                                  color: WrapdColors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(WrapdColors.radiusSmall),
                                ),
                                child: Text(
                                  action['deadline']?.toString() ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: WrapdColors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: WrapdColors.p24),
              WrapdButton(
                label: 'View All in Library',
                variant: WrapdButtonVariant.primary,
                fullWidth: true,
                onPressed: () {
                  Navigator.of(context).push(
                    WrapdNavigator.route(const LibraryScreen(assignedToMe: true)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
