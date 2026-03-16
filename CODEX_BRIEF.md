# WRAPD — Codex Build Brief
# Read this entire file before touching any code.
# This is the single source of truth for what exists, what's broken, and what to build.

---

## WHO YOU ARE BUILDING FOR

Target: 1000 paid users.
Product: WRAPD — post-meeting work eliminator.
Tagline: "The meeting already handled it."
Stack: Flutter + Supabase + on-device AI (flutter_gemma mobile, Ollama desktop, Anthropic web-dev).
Repo: /Volumes/ESD-USB/X-Builds/WRAPD

---

## WHAT ACTUALLY EXISTS (read the code, trust this map)

### WORKING ✅
- Full Flutter shell: navigation, routing (go_router), bottom nav, dark/light theme
- Session persistence: Hive local storage, SessionProvider, StorageService
- Recording screen: mic capture (AudioService + record package), waveform, timer, stop/pause
- Transcription: speech_to_text in dictation mode, partial + final stream, continuous restart loop
- RecordingProvider: wires audio + transcript streams, partial in-place updates (just fixed)
- Session detail: Transcript tab, Synthesis tab (streaming AI), Studio tab (audio playback)
- AI service: platform-routed — web→Anthropic dev key, mobile→flutter_gemma, desktop→Ollama
- RecapView: live Supabase query, actions/decisions/questions, WRAPD watermark, expired link state
- InviteHandler: deep link wrapd.ai/join?invite=[id], routes to registration with email prefill
- Supabase Edge Function: send-invite-email via Resend (supabase/functions/send-invite-email/index.ts)
- TemplateManager: scaffold with correct architecture, Supabase calls stubbed with TODOs

### BROKEN / INCOMPLETE ❌
1. RECORDING PERMISSION NEVER SHOWED (just fixed — requestPermission now calls Permission.microphone.request())
2. AUDIO PATH LOST ON STOP (just fixed — savedPath captured before state reset in audio_service.dart)
3. PARTIAL STREAM NOT SUBSCRIBED (just fixed — partialSub added in recording_provider.dart)
4. STUDIO AUDIO NEVER LOADED (just fixed — AudioProvider.loadAudio() called in SessionDetailScreen.initState)
5. DIARIZATION IS ENTIRELY FAKE — voice_diarization_service.dart emits random numbers, not real speaker detection
6. AUDIO IMPORT IS MOCKED — command_center_screen.dart creates a fake transcript instead of processing real audio
7. SUPABASE CREDENTIALS ARE PLACEHOLDERS — main.dart line 59, nothing backend-dependent works
8. WAVEFORM IN STUDIO IS SIMULATED — audio_provider.dart generates fake data, not real audio analysis
9. SPEAKER ID TOGGLE IN SETTINGS — persisted but not wired to the recording pipeline

---

## THE PRIORITY ORDER (do not deviate)

### PRIORITY 1 — VALIDATE BASIC RECORDING WORKS
Run the app. Record your voice. Confirm:
- Mic permission dialog appears on first launch
- Waveform animates while speaking
- Words appear in the transcript during recording
- Session saves and opens in Session Detail
- Studio tab shows the audio player (not "No audio recording")

If any of these fail, fix them first. Nothing else matters until this loop works.

### PRIORITY 2 — REAL SPEAKER DETECTION (replace the fake service)

The diarization service at lib/services/voice_diarization_service.dart is entirely simulated.
Replace _extractAudioFeatures() and _simulateSpeakerIdentification() with real pitch-based detection.

IMPLEMENTATION APPROACH (no external native libraries needed, pure Dart):

The AudioService already captures amplitude via _recorder.getAmplitude() on a 100ms timer.
Use this to build energy + pitch tracking:

```dart
// In voice_diarization_service.dart — replace _processAudioChunk():

// Track per-speaker running pitch average
final Map<int, double> _speakerPitchBaseline = {};
double _lastPitch = 0.0;
int _currentDetectedSpeaker = 0;

// Called every 300ms with the amplitude value from AudioService
void processAmplitudeSample(double amplitude, double pitchEstimate) {
  // Pitch change > 15% from current speaker baseline = likely new speaker
  final baseline = _speakerPitchBaseline[_currentDetectedSpeaker] ?? pitchEstimate;
  final delta = (pitchEstimate - baseline).abs() / (baseline + 0.001);
  
  if (delta > 0.15 && amplitude > 0.1) {
    // Look for a matching existing speaker or create new one
    final matchedSpeaker = _findSpeakerByPitch(pitchEstimate);
    if (matchedSpeaker != _currentDetectedSpeaker) {
      _currentDetectedSpeaker = matchedSpeaker;
      _emitSpeakerChange(_currentDetectedSpeaker);
    }
  }
  
  // Update running average for current speaker
  _speakerPitchBaseline[_currentDetectedSpeaker] = 
    (baseline * 0.9) + (pitchEstimate * 0.1); // exponential moving average
}
```

Wire pitch estimation using zero-crossing rate from the amplitude stream:
- High zero-crossing rate + low amplitude = unvoiced/silence
- Low zero-crossing rate + high amplitude = voiced speech (lower pitch)
- Use amplitude variance over 500ms windows as a simple pitch proxy

This gives real speaker change detection without any native libraries.
It won't be as accurate as Sherpa-ONNX but it will actually work and detect tone changes.

The manual speaker chip selection in RecordScreen remains as the override — users can always
correct the detected speaker. This is correct product behaviour.

### PRIORITY 3 — WIRE SUPABASE

Replace placeholder credentials in lib/main.dart (line 59):
```dart
await Supabase.initialize(
  url: 'https://placeholder.supabase.co',     // ← REPLACE
  anonKey: 'placeholder_anon_key',            // ← REPLACE
);
```

The schema is already deployed. The triggers are live. The edge function exists.
Just needs real credentials. Get them from the Supabase dashboard.

Once wired:
- RecapView (lib/screens/recap_view.dart) will work end-to-end
- InviteHandler deep links will resolve
- TemplateManager.generateTemplate() needs TODOs replaced with real RPC calls

### PRIORITY 4 — COMPLETE TEMPLATE MANAGER

lib/services/template_manager.dart has the correct structure. Replace the mock TODOs:

```dart
// GENERATE — replace mock code with:
final response = await Supabase.instance.client.rpc('generate_template_code');
final code = response as String;

await Supabase.instance.client.from('templates').insert({
  'code': code,
  'creator_id': Supabase.instance.client.auth.currentUser!.id,
  'source_session_id': session.id,
  'name': title,
  'extraction_rules': {'prompts': []},
  'recap_structure': {'order': 'actions_first'},
  'speaker_personas': [],
  'is_public': false,
});

// IMPORT — replace mock with:
final response = await Supabase.instance.client
  .from('templates')
  .select()
  .eq('code', code)
  .eq('is_public', true)
  .single();

await Supabase.instance.client.rpc('increment_template_use', 
  params: {'p_code': code});
```

---

## FILE MAP (key files only)

```
lib/
  main.dart                          ← App entry, router, Supabase init (NEEDS REAL KEYS)
  config/wrapd_config.dart           ← All config constants
  theme/wrapd_theme.dart             ← Design tokens (WrapdColors, WrapdTheme) — do not edit
  
  models/
    session_model.dart               ← WrapdSession, TranscriptSegment, TopicMarker
    speaker_profile_model.dart       ← VoiceProfile, SpeakerDiarizationResult
    workflow_model.dart              ← WorkflowAction, WorkflowPackage
  
  providers/
    recording_provider.dart          ← Wires AudioService + TranscriptionService ← JUST FIXED
    session_provider.dart            ← App-wide session state + Hive persistence
    audio_provider.dart              ← Playback (just_audio) + waveform
  
  services/
    audio_service.dart               ← Mic capture (record package) ← JUST FIXED
    transcription_service.dart       ← speech_to_text continuous loop — WORKING
    voice_diarization_service.dart   ← FAKE — needs real pitch detection ← PRIORITY 2
    ai_service.dart                  ← Platform-routed AI (web/mobile/desktop)
    template_manager.dart            ← Stubbed TODOs ← PRIORITY 4
    invite_handler.dart              ← Deep link handler — WORKING
    export_service.dart              ← Text/markdown export
    storage_service.dart             ← Hive wrapper
  
  screens/
    command_center_screen.dart       ← Home (audio import still mocked)
    record_screen.dart               ← Live recording UX ← JUST FIXED
    session_detail_screen.dart       ← Transcript + Synthesis + Studio ← JUST FIXED
    recap_view.dart                  ← Public recap page (needs real Supabase)
    settings_screen.dart             ← Speaker ID toggle needs pipeline wiring
  
  widgets/
    shared_components.dart           ← TranscriptBlock, SpeakerDot, SessionCard, WrapdButton
    share_link_button.dart           ← Share/copy recap URL widget
  
supabase/
  functions/send-invite-email/index.ts  ← COMPLETE — deploy when Supabase is wired
```

---

## DESIGN RULES (enforce these, never break them)

All colours: use WrapdColors class only. Zero magic hex.
All spacing: multiples of 4px only. Use WrapdColors.p4/p8/p12/p16/p24/p32/p48.
Fonts: Syne 800 for display, DM Sans for body. No other fonts.
Speaker colours: never show human name with speaker colour until mapping_confidence >= 0.75.
Action tiers: confirmed=emerald, needs_confirmation=amber dotted, possible=muted collapsed.

---

## WHAT NOT TO BUILD YET

- Gemma model download UI (needs flutter_gemma fully integrated first)
- Insights screen (quarantined)
- Enterprise tier
- True Sherpa-ONNX diarization (Phase 0 evaluation not complete)
- Auto-create mode for tasks (confirmation-first is the only mode)

---

## HOW TO RUN

```bash
cd /Volumes/ESD-USB/X-Builds/WRAPD
flutter clean
flutter pub get
flutter run -d chrome        # browser testing
flutter run                  # connected device
flutter run -d macos         # desktop
```

## QUICK VALIDATION CHECKLIST

Before marking anything done:
[ ] flutter analyze returns zero errors
[ ] Recording starts when mic permission granted
[ ] Words appear during recording (transcript not empty)
[ ] Session saves and appears in home screen list
[ ] Session Detail opens and shows transcript
[ ] Studio tab shows audio player (not "No audio recording")
[ ] No instances of "SCRIBE", "scribe_ai" in UI strings
[ ] All colours reference WrapdColors — no raw hex in widget code
