# Compass — anonymous youth health & sex-education app

Privacy-first Flutter frontend for a free, global, anonymous youth health and
sex-education app powered by RAG + LLMs.

**Privacy contract:** no accounts, no personal data input, chat history is
memory-only, hotlines are bundled offline, and no runtime font/CDN fetching.

## Getting started

The repo contains the Dart source only. Generate platform scaffolding once,
then run:

```bash
cd youth_health_app
flutter create . --platforms=android,ios   # generates android/ & ios/ folders
flutter pub get
flutter run
flutter test                               # smoke tests incl. panic flow
```

## Directory layout

```
youth_health_app/
├── pubspec.yaml
├── analysis_options.yaml
├── test/
│   └── widget_smoke_test.dart      # boot + panic-mask/unlock smoke tests
└── lib/
    ├── main.dart                   # ProviderScope root
    ├── app.dart                    # MaterialApp; injects PanicOverlay via builder
    ├── core/
    │   └── theme/
    │       └── app_theme.dart      # design system: palette, type, components
    ├── shell/
    │   └── main_shell.dart         # bottom navigation (IndexedStack tabs)
    └── features/
        ├── panic/                  # A. quick-exit
        │   ├── panic_provider.dart          # global panic bool
        │   ├── panic_overlay.dart           # floating button + decoy layer
        │   └── decoy_calculator_screen.dart # working fake calculator
        ├── chat/                   # B. AI chat
        │   ├── chat_screen.dart
        │   ├── models/chat_message.dart
        │   ├── providers/chat_provider.dart # streaming + RAG hook point
        │   └── widgets/
        │       ├── message_bubble.dart      # Markdown + source badges
        │       ├── typing_indicator.dart
        │       ├── quick_tag_chips.dart
        │       └── chat_input_bar.dart      # 300-char limit + counter
        ├── guides/                 # C. visual guides + story viewer
        │   ├── topic_guides_screen.dart     # hub grid
        │   ├── story_viewer_screen.dart     # swipe/tap story cards
        │   ├── models/topic_guide.dart
        │   └── providers/guides_provider.dart
        ├── mythbusters/            # D. myth vs fact deck
        │   ├── mythbusters_screen.dart      # flip cards + deck state
        │   ├── models/myth_card.dart
        │   ├── providers/myth_provider.dart
        │   └── widgets/swipe_card_stack.dart # custom dependency-free swiper
        └── hotlines/               # E. emergency directory
            ├── hotlines_screen.dart         # tap-to-call/text/web
            ├── models/hotline.dart
            └── providers/hotlines_provider.dart
```

## Key flows

- **Panic / quick exit** — a draggable floating bubble (and an eye-off icon in
  the chat app bar) sets `panicModeProvider` to `true`; `PanicOverlay`, wrapped
  around every route via `MaterialApp.builder`, instantly covers the screen
  with a *working* decoy calculator. Long-press the "Calculator" title to
  return. No animation on entry so the real screen is never partially visible.
- **Chat streaming** — `ChatNotifier.send()` appends the user bubble, then an
  empty streaming assistant bubble (rendered as pulsing dots). A word-by-word
  timer simulates the token stream; the clearly-marked
  `BACKEND INTEGRATION POINT` in `chat_provider.dart` is where the real RAG
  stream plugs in. Source badges ("Verified: WHO Guidelines") attach on
  completion.
- **Story viewer** — Instagram-style: segmented progress bar, tap right/left
  thirds to advance/rewind, horizontal swipe supported, provenance label on
  the final card.
- **MythBusters** — custom `SwipeCardStack` (drag, velocity fling, spring-back,
  peek cards); tap flips Myth → Fact with a Y-axis rotation.

## Deliberate choices

- **No `google_fonts`** — it downloads fonts at runtime; a silent network call
  has no place in a privacy-first app. Bundle `.ttf` assets if custom type is
  needed.
- **No persistence layer at all** — chat state dies with the process.
- **Hotline numbers are placeholders to verify** — re-check every entry against
  the operator's official site before each release.
