# orbit

**orbit** hilft dir, Menschen mit denselben Interessen zu finden. Statt endlos zu scrollen trittst du kleinen Gruppen — sogenannten **Circles** — bei, die um gemeinsame Themen entstehen. So lernst du Leute kennen, die wirklich auf derselben Wellenlänge sind.

## Features

- **Circles** — Erstelle oder tritt Gruppen mit gemeinsamen Interessen bei
- **Entdecken** — Finde neue Circles, gefiltert nach Kategorien oder per Suche; die Sortierung richtet sich nach deinen eigenen Interessen
- **Chat** — Echtzeit-Nachrichten innerhalb eines Circles
- **Einladungen & Beitrittsanfragen** — Lade Mitglieder ein oder verwalte Anfragen als Admin
- **Profil** — Profilbild, Interessen, Badges
- **Push-Notifications** — Benachrichtigungen bei Einladungen und Anfragen (Firebase Cloud Messaging)
- **Light & Dark Mode** — Material Design 3, System-Theme-Support

## Tech Stack

| Bereich | Technologie |
|---|---|
| Framework | Flutter / Dart |
| Auth | Firebase Authentication + Google Sign-In |
| Datenbank | Cloud Firestore |
| Push | Firebase Cloud Messaging |
| Bilder | Image Picker |
| UI | Material Design 3 |

## Voraussetzungen

- Flutter SDK `^3.12.2`
- Dart SDK (im Flutter-SDK enthalten)
- Ein Firebase-Projekt mit aktivierter Authentication, Firestore und Cloud Messaging
- `google-services.json` (Android) und `GoogleService-Info.plist` (iOS) im richtigen Verzeichnis

## Setup

```bash
# Abhängigkeiten installieren
flutter pub get

# App starten
flutter run
```

Für einen Release-Build (Android):
```bash
flutter build apk --release
```

## Projektstruktur

```
lib/
├── constants/        # Interessen, Badges, Icons, Farben
├── models/           # Datenmodelle (Circle, Invite, JoinRequest, …)
├── screens/          # Alle Screens (Login, Main, Discover, Profile, …)
├── services/         # Dienste (z. B. ChatService)
├── widgets/          # Wiederverwendbare Widgets (UserBadges, ChatWidget)
├── firebase_options.dart
└── main.dart
```

## Android-Installation (APK)

Siehe [RELEASE_NOTES.md](RELEASE_NOTES.md) für die Schritt-für-Schritt-Anleitung zur manuellen APK-Installation.

**Anforderungen:** Android 6.0 oder höher
