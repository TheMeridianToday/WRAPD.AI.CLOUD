# Upload WRAPD Without Git Or Developer Tools

This guide exists for cases where the local machine cannot support full developer tooling, but the source still needs to be moved into the cloud for agents and collaborators.

## Goal

Get WRAPD into a cloud-accessible repo without relying on:

- local git workflows
- GitHub CLI
- Xcode / Apple developer tools

## Recommended Low-Tool Path

Use the GitHub web interface.

This avoids local git entirely.

## What To Upload

Upload the source of truth, not generated output.

Keep:

- `lib/`
- `test/`
- `supabase/`
- `web/`
- `android/`
- `ios/`
- `macos/`
- `windows/`
- `linux/`
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `README.md`
- `CODEX_BRIEF.md`
- `ONLINE_AGENT_HANDOFF.md`
- `UPLOAD_WITHOUT_GIT.md`
- other root docs you want agents to read

Do not prioritize uploading:

- `build/`
- `.dart_tool/`
- IDE junk
- local caches
- temporary artifacts

## Why

Cloud agents need:

- source code
- architecture docs
- context docs
- product truth

They do not need stale generated build files.

## Browser Upload Flow

1. Create a new private GitHub repository from the browser.
2. Name it something stable like `wrapd-app`.
3. Upload the curated source files and folders.
4. Make sure the root of the repo includes:
   - `README.md`
   - `CODEX_BRIEF.md`
   - `ONLINE_AGENT_HANDOFF.md`
5. Once uploaded, use the repo URL as the source of truth for online agents.

## What Agents Should Read First

Tell agents to start with:

1. `README.md`
2. `CODEX_BRIEF.md`
3. `ONLINE_AGENT_HANDOFF.md`

That reduces repeated explanation and gives them architecture plus business context.

## Suggested Repo Description

Use a repo description like:

`WRAPD - AI meeting execution app built in Flutter. Record, transcribe, recap, and close the loop on meetings.`

## Suggested First Pinned Files

If the platform supports pinned files or highlighted docs, pin:

- `README.md`
- `CODEX_BRIEF.md`
- `ONLINE_AGENT_HANDOFF.md`

## Operational Benefit

Once uploaded, you gain:

- cloud-readable source of truth
- easier collaboration
- better handoff to online agents
- less repeated founder explanation
- a repo that can support more autonomous business operations

## Important Note

If local git is unavailable, that does **not** block cloud availability.

You can still create a strong cloud operating model by:

- keeping docs current
- uploading source manually through the browser
- treating the cloud repo as the canonical business-facing software asset
