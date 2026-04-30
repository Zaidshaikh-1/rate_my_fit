# Rate My Fit — Flutter Template

Dark streetwear aesthetic. Vibe card rating system. Built for Phase 1 MVP.

---

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── theme/
│   └── app_theme.dart         # Colors, typography, ThemeData
├── screens/
│   ├── shell_screen.dart      # Bottom nav shell
│   └── home_screen.dart       # Feed + vibe card rating
└── widgets/
    ├── fit_card.dart           # Outfit post card
    └── vibe_card_button.dart   # 🔥😎😐💀 rating buttons
```

---

## Getting Started

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Font setup (Syne)
Option A — Use google_fonts package (already in pubspec):
```dart
// In app_theme.dart, swap fontFamily: 'Syne' with:
import 'package:google_fonts/google_fonts.dart';
textTheme: GoogleFonts.syneTextTheme(ThemeData.dark().textTheme)
```

Option B — Download from fonts.google.com/specimen/Syne
and place in `assets/fonts/`, then uncomment the flutter.fonts section in pubspec.yaml.

### 3. Run the app
```bash
flutter run
```

---

## Firebase Setup (when ready)

1. Create a project at console.firebase.google.com
2. Add iOS + Android apps
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Uncomment firebase deps in pubspec.yaml
5. Run `flutter pub get`
6. Add `await Firebase.initializeApp()` to main()

---

## Vibe Score Weights

| Vibe    | Score |
|---------|-------|
| 🔥 Drip  | 100   |
| 😎 Clean | 75    |
| 😐 Mid   | 40    |
| 💀 Not it| 10    |

Average score = sum of (vote × weight) / total votes

---

## Phase 1 TODOs

- [ ] Wire Firebase Auth (Google sign-in recommended)
- [ ] Replace sample data with Firestore stream in home_screen.dart
- [ ] Build post_screen.dart (image_picker → Firebase Storage → Firestore write)
- [ ] Write Firestore security rules
- [ ] Add one-post-per-day enforcement (Cloud Function or security rule)
