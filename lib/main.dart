import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'providers/session_provider.dart';
import 'providers/workflow_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/recording_provider.dart';
import 'models/session_model.dart';
import 'models/workflow_model.dart';
import 'models/speaker_profile_model.dart';
import 'theme/app_theme.dart';
import 'screens/command_center_screen.dart';
import 'screens/library_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/workflow_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recap_view.dart';
import 'config/wrapd_config.dart';
import 'services/storage_service.dart';
import 'services/invite_handler.dart';
import 'services/crash_reporting_service.dart';
import 'services/performance_service.dart';
import 'services/voice_diarization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Hive must be initialized first — everything else depends on it ──
  await Hive.initFlutter();

  // ── 2. Register all adapters before opening any boxes ──
  // Session models (typeIds 0–6)
  Hive.registerAdapter(WrapdSessionAdapter());
  Hive.registerAdapter(SessionStatusAdapter());
  Hive.registerAdapter(ExportTierAdapter());
  Hive.registerAdapter(TranscriptSegmentAdapter());
  Hive.registerAdapter(TopicMarkerAdapter());
  Hive.registerAdapter(SynthesisMessageAdapter());
  Hive.registerAdapter(TimestampChipAdapter());
  // Workflow models (typeIds 10–12)
  Hive.registerAdapter(ExportTargetTypeAdapter());
  Hive.registerAdapter(WorkflowActionAdapter());
  Hive.registerAdapter(WorkflowPackageAdapter());
  // Speaker models (typeIds 20–21 — must not collide with above)
  Hive.registerAdapter(SpeakerGenderAdapter());
  Hive.registerAdapter(VoiceProfileAdapter());

  // ── 3. Open Hive boxes ──
  await StorageService().initialize();

  // ── 4. Now initialize services that depend on open boxes ──
  await CrashReportingService.initialize();
  PerformanceService.initialize();
  await voiceRecognitionService.initialize();

  // ── 5. Initialize Supabase ──
  await Supabase.initialize(
    url: WrapdConfig.supabaseUrl,
    anonKey: WrapdConfig.supabaseAnonKey,
  );

  // ── 6. Wire router reference into InviteHandler for deep-link navigation ──
  InviteHandler.setRouter(_router);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => WorkflowProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RecordingProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: const WrapdApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return Consumer<SessionProvider>(
          builder: (context, sessionProvider, _) {
            final bool showOnboarding = sessionProvider.userName == 'User' && sessionProvider.sessions.isEmpty;
            return showOnboarding ? const OnboardingScreen() : const MainNavigationHolder();
          },
        );
      },
    ),
    GoRoute(
      path: '/join',
      builder: (context, state) {
        // Handle deep link logic for invites
        WidgetsBinding.instance.addPostFrameCallback((_) {
          InviteHandler.handleDeepLink(state.uri);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    ),
    GoRoute(
      path: '/r/:hash',
      builder: (context, state) {
        final hash = state.pathParameters['hash']!;
        return RecapView(hash: hash);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final email = (state.extra as Map<String, dynamic>?)?['email'] as String? ?? '';
        return OnboardingScreen(prefillEmail: email);
      },
    ),
  ],
);

class WrapdApp extends StatelessWidget {
  const WrapdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'WRAPD',
          theme: themeProvider.currentTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}

class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int currentIndex = 0;
  
  final List<Widget> screens = [
    const CommandCenterScreen(),
    const LibraryScreen(),
    const InsightsScreen(),
    const WorkflowScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) => setState(() => currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Facts',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Workflow',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
