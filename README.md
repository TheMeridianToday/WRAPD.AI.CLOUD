# WRAPD

WRAPD is an AI-powered meeting execution app built in Flutter.

Its job is simple:

- capture meetings
- transcribe speech
- identify speakers
- extract actions and decisions
- generate recaps
- reduce the manual cleanup work that usually starts after the meeting

The core product promise is:

**The meeting already handled it.**

## Start Here

If you are an engineer, agent, or collaborator entering this repo cold, read these files first:

1. `CODEX_BRIEF.md`
2. `ONLINE_AGENT_HANDOFF.md`
3. `lib/main.dart`
4. `lib/screens/record_screen.dart`
5. `lib/providers/recording_provider.dart`
6. `lib/services/audio_service.dart`
7. `lib/services/transcription_service.dart`
8. `lib/screens/session_detail_screen.dart`

## Repo Structure

Main app code lives in:

- `lib/`
- `test/`
- `supabase/`

Important areas:

- `lib/models/` - session, speaker, and workflow data models
- `lib/providers/` - app state and recording coordination
- `lib/services/` - recording, transcription, AI, storage, export, invite, and template logic
- `lib/screens/` - product UI
- `lib/widgets/` - shared UI components
- `lib/theme/` - WRAPD design tokens and theme behavior
- `lib/config/` - constants and environment configuration
- `supabase/functions/` - backend edge functions

## Current Product Focus

The active product focus is the recording loop:

**Record -> Transcribe -> Save -> Review -> Share -> Act**

The biggest operational priority is getting this flow stable:

1. live recording starts
2. transcription appears in real time
3. session saves correctly
4. session detail opens correctly

## Cloud / Agent Use

This repo is being prepared to support cloud-based agents and remote business operations.

If you want to upload the current app without relying on local developer tools, use:

- `UPLOAD_WITHOUT_GIT.md`

If you want agents to understand the business and codebase without repeated explanation, use:

- `ONLINE_AGENT_HANDOFF.md`

## Important Notes

- This repo does **not** currently use a local `.git` directory.
- The machine may not have full Apple developer tools installed.
- Build artifacts in `build/` are not the source of truth.
- Generated files and local cache should not be treated as canonical product state.

## Brand Truth

WRAPD is not just a transcription app.

It is a product that turns conversation into completion.

**THAT'S A WRAPD.**
