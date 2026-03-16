// wrapd_config.dart — WRAPD App Configuration
class WrapdConfig {
  // ── Recording ──────────────────────────────────────────
  static const int maxSpeakers = 6;
  static const double confidenceThreshold = 0.7;
  static const int defaultExportAllowance = 3;
  static const int waveformBufferLength = 20;
  static const Duration speakerChangeInterval = Duration(seconds: 15);
  static const Duration waveformUpdateInterval = Duration(milliseconds: 100);
  static const bool simulateSpeakerChanges = false;

  // ── On-Device AI — Mobile (flutter_gemma) ─────────────
  // Gemma 3 270M: ~270MB one-time download, runs fully offline.
  // GPU accelerated via MediaPipe. Zero cloud calls.
  static const String gemmaModelName = 'gemma-3-270m-it';

  // ── Local AI — Desktop (Ollama fallback) ──────────────
  // Requires: ollama serve && ollama pull llama3.2:1b
  static const String ollamaModel = 'llama3.2:1b';
  // Android emulator → host machine. Use LAN IP for physical device.
  static const String ollamaHost = '10.0.2.2';

  // ── Dev AI — Web browser testing (Anthropic) ──────────
  // Used ONLY when running flutter run -d chrome for testing.
  // Add your dev API key here. Never ships in mobile builds.
  // Leave empty to get a friendly stub response instead.
  static const String anthropicDevKey = ''; // 'sk-ant-...'

  // ── Backend — Supabase ────────────────────────────────
  // Prefer passing real values with --dart-define at build/run time.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder_anon_key',
  );
}
