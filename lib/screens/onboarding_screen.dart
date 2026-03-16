import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/wrapd_theme.dart';
import '../widgets/shared_components.dart';
import '../providers/session_provider.dart';

class OnboardingScreen extends StatefulWidget {
  /// Optional email to prefill when arriving via an invite deep link.
  final String prefillEmail;

  const OnboardingScreen({super.key, this.prefillEmail = ''});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();

  final List<Map<String, String>> _pages = [
    {
      'title': 'The Professional Recording Instrument',
      'message': 'WRAPD is your final stop for meeting management, transcribing every word with precision.',
      'icon': 'mic',
    },
    {
      'title': 'Fact-Based Synthesis',
      'message': 'No bias, no creative fluff. Our AI extracts raw facts, decisions, and thesis points directly from your audio.',
      'icon': 'auto_awesome',
    },
    {
      'title': 'Offline-First Privacy',
      'message': 'Your data stays on your device. Secure, encrypted, and ready for workflow automation.',
      'icon': 'security',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i < _pages.length) {
                        final p = _pages[i];
                        return Padding(
                          padding: const EdgeInsets.all(WrapdColors.p32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: WrapdColors.cobalt.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIcon(p['icon']!),
                                  size: 80,
                                  color: WrapdColors.cobalt,
                                ),
                              ),
                              const SizedBox(height: 48),
                              Text(p['title']!,
                                  style: theme.textTheme.headlineMedium,
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              Text(p['message']!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted,
                                  ),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(WrapdColors.p32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Ready to start?', style: theme.textTheme.headlineMedium),
                              if (widget.prefillEmail.isNotEmpty) ...[
                                const SizedBox(height: WrapdColors.p16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: WrapdColors.p16, vertical: WrapdColors.p12),
                                  decoration: BoxDecoration(
                                    color: WrapdColors.cobalt.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(WrapdColors.radius),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.mail_outline_rounded,
                                          color: WrapdColors.cobalt, size: 16),
                                      const SizedBox(width: WrapdColors.p8),
                                      Expanded(
                                        child: Text(
                                          'Joining as ${widget.prefillEmail}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: WrapdColors.cobalt,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: WrapdColors.p32),
                              TextField(
                                controller: _nameController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  labelText: 'Your Name',
                                  hintText: 'How should Wrapd greet you?',
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
                
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length + 1, (index) => 
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? WrapdColors.cobalt : WrapdColors.darkBorder,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(WrapdColors.p32),
                  child: WrapdButton(
                    label: _currentPage == _pages.length ? 'Get Started' : 'Next',
                    fullWidth: true,
                    onPressed: () {
                      if (_currentPage < _pages.length) {
                        _pageController.nextPage(duration: WrapdColors.normal, curve: Curves.easeInOut);
                      } else {
                        final name = _nameController.text.trim();
                        context.read<SessionProvider>().setUserName(name.isEmpty ? 'User' : name);
                      }
                    },
                  ),
                ),
              ],
            ),
            
            if (_currentPage < _pages.length)
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: () {
                    context.read<SessionProvider>().setUserName('User');
                  },
                  child: Text('Skip', style: TextStyle(color: isDark ? WrapdColors.darkMuted : WrapdColors.lightMuted)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'mic': return Icons.mic_rounded;
      case 'auto_awesome': return Icons.auto_awesome_rounded;
      case 'security': return Icons.security_rounded;
      default: return Icons.star_rounded;
    }
  }
}
