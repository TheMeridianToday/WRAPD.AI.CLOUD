# THE WRAPD ARCHITECTURE BLUEPRINT (v3.0)

This document is the **master blueprint** for rapidly building, scaling, and shipping Flutter applications with maximum efficiency and minimal bugs. It is designed to take an idea to a shippable application in **less than 24 hours**.

---

## 1. Core Philosophy: The 5 Pillars of Separation

To guarantee zero tightly-coupled "spaghetti" code, every app is divided into five rigid pillars:
1. **Data Models (`lib/models/`)**: Pure Dart classes + Hive Adapters (e.g., `WorkflowAction`, `WrapdSession`).
2. **State Management (`lib/providers/`)**: Event-driven `ChangeNotifier` classes that bridge UI and Services.
3. **Hardware & APIs (`lib/services/`)**: **[NEW]** Singletons that handle hardware logic (e.g., `AudioService`, `TranscriptionService`). Keeps `providers` clean.
4. **Core UI & Theming (`lib/theme/` & `lib/widgets/`)**: Design tokens and reusable components.
5. **Feature Screens (`lib/screens/`)**: Top-level views consuming state.

---

## 2. Directory Structure Template

Replicate this exact folder structure for every new project:

```text
lib/
 ├── main.dart                  # Entry Point & Global App Shell
 ├── models/                    # Data shapes & Hive Adapters
 ├── providers/                 # Business logic & State
 ├── screens/                   # Page-level UI
 ├── services/                  # Hardware, APIs, File Systems
 ├── theme/                     # Design Tokens & Theme Law
 └── widgets/                   # Master Reusable Components
```

---

## 3. The Design System (The "Law")

Never use "magic numbers" or ad-hoc colors. All UI must be driven by a central **Token System**.

### The 8-Point Grid Rule
Absolute spacing avoids "messy" layouts.
```dart
class AppTokens {
  static const double p4 = 4.0;
  static const double p8 = 8.0;   // The Base Unit
  static const double p16 = 16.0; // The Standard Padding
  static const double p24 = 24.0; // Large Spacing
}
```

### Visual Aesthetic: "Anthropic Clean"
- **Surfaces**: Use subtle gradients and 0.5px borders for a premium feel.
- **Typography**: Inter or Roboto with clear weight hierarchies (Bold for titles, Medium for body).
- **Transitions**: Use `WrapdColors.normal` (250ms) for all micro-animations.

---

## 4. Initialization & State Management

### Error Prevention in `main()`
The following setup is **non-negotiable** for offline-first apps:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 1. Bind Flutter
  await Hive.initFlutter();                  // 2. Init Storage
  
  // 3. Register ALL Class Adapters here before runApp
  Hive.registerAdapter(WrapdSessionAdapter()); 
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => WorkflowProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const GlobalAppShell(),
    ),
  );
}
```

---

## 5. Navigation Strategy (High-Efficiency)

For multi-tab apps, **never use `Navigator.push` for tab switching**. Use an `IndexedStack` inside an `AppShell`.

**Why?**
- **Persistence**: Scroll positions and text fields are preserved across tab swaps.
- **Speed**: Switching tabs is instantaneous (0ms latency).
- **Value**: The app feels like a single, cohesive "instrument" rather than a series of disconnected pages.

---

## 6. The "Final Stop" Automation Pattern (NEW in v3.0)
Modern apps often require automated actions after data collection. Implement a `WorkflowProvider` to handle automated CRM / Calendar / Email integrations asynchronously. 
- Build a dedicated `WorkflowScreen` as a tab.
- Queue tasks like document generation (`Notion`/`OneDrive`), communications (`Slack`/`Teams`), and calendar invites (`Google Calendar`) in the background based on session data.

---

## 7. Environment Setup (Troubleshooting)

If `'flutter' is not recognized` occurs:
1. **CMD Fix**: Use the full path: `C:\flutter\bin\flutter.bat run`.
2. **Permanent Fix**: Add `C:\flutter\bin` to your Windows **Environment Variables (PATH)**.
3. **PowerShell Fix**: Use the call operator: `& "C:\flutter\bin\flutter.bat" run`.

---

## 8. The 24-Hour "Idea to Ship" Checklist

### Phase 1: The Core (Hours 1-4)
- [ ] **Scaffold**: Create the 6 core directories.
- [ ] **Tokens**: Define primary colors, spacing, and border radii.
- [ ] **Models**: Write the core PODOs (Plain Old Dart Objects).
- [ ] **Services**: Set up singletons (`AudioService.dart`, `StorageService.dart`).

### Phase 2: The UI Instrument (Hours 5-12)
- [ ] **AppShell**: Build the Bottom Nav + IndexedStack.
- [ ] **Shared Widgets**: Build the primary Button and Card styles.
- [ ] **Screens**: Map the `Provider` data to the screens using `context.watch`.

### Phase 3: Polish, Automate & Publish (Hours 13-24)
- [ ] **Automation**: Integrate the "Final Stop" workflow queue.
- [ ] **Theme Toggle**: Ensure Dark/Light mode is flawless.
- [ ] **Asset Prep**: Use `generate_image` or DALL-E for high-quality app icons and screenshots.
- [ ] **Deployment**: Run `flutter build web` or `flutter build apk`.
