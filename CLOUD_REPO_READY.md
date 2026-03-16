# WRAPD Cloud Repo Readiness

This document turns WRAPD from a local code folder into a cloud-readable software asset.

The goal is simple:

- give online agents a stable source of truth
- reduce repeated founder explanation
- make the app understandable from docs plus source
- avoid dependence on local git or full developer tooling

## Current Reality

WRAPD already has the core ingredients needed for a cloud operating model:

- a clear Flutter app structure
- source code separated into `models/`, `providers/`, `services/`, `screens/`, and `widgets/`
- a strong product brief in `CODEX_BRIEF.md`
- a handoff document in `ONLINE_AGENT_HANDOFF.md`
- a root `README.md` that explains the product and where to start

That means the app is already structurally suitable for cloud handoff.

The missing piece is not architecture.

The missing piece is treating the repo as the canonical business-facing software reference.

## What "Cloud Based" Means Here

For WRAPD, the fastest practical cloud model is:

1. store the source in a private GitHub repository
2. keep the key documents at the repo root
3. make that repo the place online agents inspect first
4. use browser-based upload if local git is unavailable

This is enough to support:

- remote agent onboarding
- cloud-based code review
- async collaboration
- structured business operations around the software

## Required Root Documents

These files should always exist at the root of the cloud repo:

- `README.md`
- `CODEX_BRIEF.md`
- `ONLINE_AGENT_HANDOFF.md`
- `UPLOAD_WITHOUT_GIT.md`
- `CLOUD_REPO_READY.md`

These five files let an online agent quickly understand:

- what WRAPD is
- what matters most
- what to read first
- how to move the code into the cloud
- how the repo should be treated operationally

## What Must Be Uploaded

Source of truth:

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
- root docs

Helpful optional files:

- `marketing-team/`
- `MARKETING_AND_SALES_MASTER_PLAN.md`
- launcher scripts if useful for local operators

## What Should Not Be Treated As Canonical

These should not define product truth:

- `build/`
- `.dart_tool/`
- IDE folders
- temporary output logs
- stale generated files
- AppleDouble files like `._*`

## Recommended Cloud Workflow

### Phase 1: Upload

- create a private GitHub repo
- upload a clean source snapshot through the browser
- verify the root docs are visible immediately

### Phase 2: Orient Agents

Tell every online agent:

1. read `README.md`
2. read `CODEX_BRIEF.md`
3. read `ONLINE_AGENT_HANDOFF.md`
4. then inspect `lib/main.dart`
5. then inspect the recording flow

This avoids repeated explanation.

### Phase 3: Operate From The Repo

Use the cloud repo as the software source of truth for:

- new contributors
- autonomous agents
- bug triage
- architecture review
- marketing/product alignment

## Immediate Priority Inside The Codebase

Cloud visibility is important, but the highest product priority remains:

1. live recording works
2. transcription appears
3. session saves
4. session opens correctly

That should remain the main engineering focus even after cloud upload.

## Definition Of Done

WRAPD is "cloud-ready enough" when:

- the code is in a private remote repo
- the root docs explain the app clearly
- online agents can inspect the repo without founder re-explaining the product
- the recording loop is clearly documented as the current execution priority

## Operational Principle

The cloud repo is not just a backup.

It should become the shared software memory for the business.
