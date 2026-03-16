# WRAPD Online Agent Handoff

This file exists so cloud-based agents, remote collaborators, and autonomous systems can understand WRAPD without the founder having to re-explain the app every time.

## What WRAPD Is

WRAPD is a premium AI-powered meeting execution product.

It is designed to:

- record meetings
- transcribe speech
- identify speakers
- structure transcripts
- extract action items
- extract decisions
- generate recaps
- help close the loop after meetings

It should feel like:

- premium
- calm
- intelligent
- operational
- not generic AI software

Core line:

**The meeting already handled it.**

Brand sign-off:

**THAT'S A WRAPD.**

## Product Mental Model

Think of WRAPD as:

**Record -> Understand -> Organize -> Recap -> Execute**

The product is not supposed to end at "transcription complete."

It is supposed to reduce the business work that starts after a meeting.

## Core User Journey

1. User opens home screen / command center.
2. User starts live recording.
3. WRAPD records and transcribes in real time.
4. Speakers are labeled or detected.
5. Meeting is saved as a session.
6. User opens session detail.
7. WRAPD provides transcript, synthesis, and studio playback.
8. WRAPD supports recap sharing and action-oriented post-meeting workflows.

## What Matters Most Right Now

The most important engineering priority is the recording loop.

That means all work should be biased toward making this reliable:

1. start recording
2. see transcript
3. stop recording
4. save session
5. open session detail

If this loop is unstable, everything else is secondary.

## Current Architecture

### `lib/main.dart`
Bootstraps the app, Hive, providers, routing, Supabase, and startup services.

### `lib/models/`
Contains:

- session models
- speaker models
- workflow models

### `lib/providers/`
Contains:

- `session_provider.dart` for persistent app/session state
- `recording_provider.dart` for live recording/transcription coordination
- `audio_provider.dart` for playback
- `workflow_provider.dart` for post-meeting actions

### `lib/services/`
Contains:

- `audio_service.dart` for recording and waveform behavior
- `transcription_service.dart` for speech-to-text
- `voice_diarization_service.dart` for speaker detection/profile logic
- `ai_service.dart` for synthesis and AI analysis
- `storage_service.dart` for Hive persistence
- `template_manager.dart` for template code generation/import
- `invite_handler.dart` for deep links
- `export_service.dart` for export

### `lib/screens/`
Important screens:

- `command_center_screen.dart`
- `record_screen.dart`
- `session_detail_screen.dart`
- `workflow_screen.dart`
- `settings_screen.dart`
- `recap_view.dart`

## Current Product Truth

The app shell is real.
The product idea is strong.
The architecture is good enough to scale.

But there are still practical gaps between product vision and stable execution.

## Current Known Gaps

These are the areas an online agent should assume may need attention:

1. transcription reliability across targets, especially browser behavior
2. recording start/save stability
3. web versus native differences in speech recognition permissions
4. true diarization quality
5. real audio import flow
6. real waveform extraction in studio playback
7. Supabase credentials and cloud wiring
8. stronger repo documentation for outside agents

## What Not To Assume

Do not assume:

- the `build/` folder reflects the latest source edits
- browser behavior matches macOS or mobile behavior
- every feature labeled in UI is production-complete
- diarization is fully production-grade
- imports/sharing/workflow are finished end to end

## What To Read First

For the fastest code understanding, read in this order:

1. `CODEX_BRIEF.md`
2. `README.md`
3. `lib/main.dart`
4. `lib/screens/record_screen.dart`
5. `lib/providers/recording_provider.dart`
6. `lib/services/audio_service.dart`
7. `lib/services/transcription_service.dart`
8. `lib/screens/session_detail_screen.dart`
9. `lib/providers/session_provider.dart`
10. `lib/services/ai_service.dart`

## Business Intent

WRAPD is meant to support a more autonomous business model.

That means the software should eventually become easy for:

- online agents to inspect
- cloud tools to reason about
- remote operators to maintain
- collaborators to understand quickly

The repo should therefore always optimize for:

- clarity
- stable file organization
- docs that explain the product truth
- obvious high-priority workflows
- minimal ambiguity about what is real versus mocked

## Source Of Truth

When there is tension between generated build output and source code, trust source code.

When there is tension between broad ambition and current operational reality, trust the current operational bottleneck:

**recording and transcription must work first**

## Desired Future State

The repo should become:

- uploadable to cloud platforms without local developer tool dependency
- understandable by autonomous agents
- easy to audit
- easy to hand off
- a stable operational asset, not just a local code folder

That is the point of this document.
