# WRAPD BRAND LANGUAGE GUIDE
**Industrial Intelligence + Approachable Personality**  
**Version:** 1.0 | **Date:** March 16, 2026

---

## CORE BRAND PHILOSOPHY

WRAPD is **serious technology** wrapped in **approachable design**.

Think: Claude's personality (helpful, direct, witty) but for a meeting recorder.

**The app is professional. The mascot is friendly. Never confuse the two.**

---

## WALDO THE WRAPRUS — Mascot & Personality

### Visual Identity
- **Character:** Pixelated wraprus (walrus + WRAPD mashup)
- **Color:** Emerald teal (#1DB7B3, primary color)
- **Personality traits:** Curious, capable, slightly mischievous, deeply competent
- **Vibe:** "I've got your back, and I'm having fun doing it"

### Behavior States (from Asset Board)

| State | Use Case | Context |
|-------|----------|---------|
| **Concentrated Focus** (glasses on) | Processing, analyzing, thinking hard | During transcription, diarization, summarization |
| **Status Alert / Uncertain** (orange) | Something needs attention | Error states, needs user action |
| **Resolution Complete** (checkmark) | Success, recap finished, actions exported | Completion screens |
| **Assistant Ready** (happy, listening) | Waiting for input, ready to record | Idle state, record button screen |

### When to Use Waldo
✅ **DO:** Onboarding screens, empty states, success confirmations, error states, loading animations  
❌ **DON'T:** Functional UI elements, buttons, settings, transcript text, recap text

**Rule:** Waldo appears as **occasional moments of delight**, not constant decoration.

---

## VISUAL LANGUAGE

### Color Palette (The Harmonic Palette)

| Name | Hex | Use |
|------|-----|-----|
| **Emerald (Primary)** | #1DB7B3 | Primary CTAs, active states, brand accent |
| **Cobalt (Secondary)** | #0A3CFF | Secondary actions, links, highlights |
| **Amber (Warning)** | #FFB020 | Alerts, needs attention, caution |
| **Rose (Error)** | #FF5A7A | Critical errors, deletion warnings |
| **Violet (Premium/Advanced)** | #7A50FF | Optional features, v2 features, "upgrade" hints |
| **Slate (Neutral)** | #6F7280 | Text, borders, disabled states |

### Typography

**Display (Headlines):** `Syne 800` (bold, tech-forward, slightly geometric)  
**Body (UI + Transcript):** `DM Sans 400` (clean, readable, professional)  
**Monospace (Timestamps):** System monospace or `JetBrains Mono`

### Spacing & Grid
- **Base unit:** 4px
- **All spacing:** Multiples of 4px only (4, 8, 12, 16, 24, 32, 48, 64)
- **Never:** 3px, 5px, 7px, etc.

---

## TONE OF VOICE

### In the App (Functional)
**Direct. Confident. Zero fluff.**

✅ Good:
- "Recording..." (not "We're listening intently...")
- "3 action items" (not "Look what we found!")
- "No speakers detected — check mic" (not "Oops, we couldn't hear anyone...")

❌ Bad:
- Over-explaining errors
- Using "Waldo says" in functional text
- Cute emojis in error messages

### In Marketing / Onboarding
**Friendly. Confident. Slightly playful.**

✅ Good:
- "Your meetings, wrapped." (tagline)
- "Record. Auto-summarize. Share recap." (feature flow)
- "No cloud. No tokens. No nonsense." (privacy hook)

### Waldo's Voice (Rare, Use Sparingly)
When Waldo appears in a screen:
- **Onboarding:** "Hey! I'm Waldo. I'll help you turn meetings into action."
- **Empty state:** "No meetings yet. Ready when you are."
- **Success:** "That's a WRAPD." (pun on "That's a wrap" + brand name)
- **Error:** "Huh, something went sideways. Let me know what happened."

**Rule:** Waldo speaks once, max twice per user session. Don't over-use him.

---

## DESIGN RULES (Never Break These)
- All colours: `WrapdColors` class only — zero magic hex
- All spacing: multiples of 4px only
- Fonts: **Syne 800** for display, **DM Sans** for body
- Speaker colours: never show human name until `mapping_confidence >= 0.75`
- Action tiers: confirmed=emerald, needs_confirmation=amber dotted, possible=muted collapsed
- Zero instances of "SCRIBE" or "scribe_ai" anywhere in UI strings

---

## DO's & DON'Ts

| DO | DON'T |
|----|-------|
| Use Waldo in onboarding & empty states | Use Waldo constantly (dilutes impact) |
| Keep Waldo's design pixel-perfect | Blur, distort, or re-pose Waldo |
| Use emerald for primary CTAs | Use multiple brand colors in one button |
| Write functional UI in active voice | Explain errors cutely ("Oops!") |
| Maintain 4px spacing grid rigorously | Use arbitrary spacing (3px, 7px, 13px) |
| Name speakers with confidence ≥75% | Show "Speaker A" before you're sure |
| Use Syne 800 for titles, DM Sans for body | Mix typefaces or use non-approved fonts |
| Export actual transcript words for recap | Generate new text (v1 rule) |
| Talk about privacy & offline clearly | Make vague claims ("secure," "private") |
| **This is a meeting tool.** Make it work first. | Make it cute first. Make it work second. |

---

## BRAND VOICE EXAMPLES

### Good Recap Output
```
MEETING RECAP — Q1 Planning — Mar 16, 2026

SUMMARY
We discussed the Q1 roadmap, focusing on 
diarization accuracy and offline support. 
Team agreed to prioritize speaker ID over 
advanced summarization in v1.

DECISIONS
• Whisper Tiny Q4 for STT (20 MB)
• TitaNet Q3 for diarization (3 MB)
• TextRank for summarization (0 MB, v1)

ACTION ITEMS
• Validate stack in Colab — Owner: Claude — Due: Mar 18
• Integrate whisper.cpp bindings — Owner: Dev — Due: Mar 22
• Test on real meeting audio — Owner: Dr. Keys — Due: Mar 25
```

### Good Error Message
```
❌ No speakers detected
Check your mic and try again.
```

### Good Empty State
```
🦭 No meetings yet.
Ready when you are.

[Start Recording]
```

---

## FINAL RULE

**The app works first. The personality is a bonus.**

If choosing between:
- Waldo looking cute VS. showing critical information → Show the information
- Emerald accent VS. clarity of button function → Choose clarity
- Fun copy VS. precise instructions → Choose precision

Personality serves the product, not the other way around.

---

**Version:** 1.0  
**Status:** Ready for implementation  
**Last Updated:** March 16, 2026
