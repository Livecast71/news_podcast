# News Podcast

A modern Flutter application for listening to podcasts and reading news articles with voice control support. Features a beautiful dark theme, background audio playback, and hands-free voice commands.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.9.2+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 Features

- **🎙️ Podcast Playback**: Browse and listen to podcasts with a beautiful, intuitive interface
- **📰 News Articles**: Read the latest news articles with a clean, readable layout
- **🎤 Voice Commands**: Control playback hands-free with natural language voice commands
- **🔊 Background Audio**: Continue listening while using other apps with lock screen controls
- **🌙 Dark Theme**: Beautiful dark theme with amber accents for comfortable viewing
- **📱 Cross-Platform**: Works on iOS, Android, Web, macOS, Linux, and Windows

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.9.2 or higher)
  - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Verify installation: `flutter doctor`
- **Dart SDK** (comes with Flutter)
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA with Flutter plugins
- **Platform-specific tools**:
  - **iOS**: Xcode (macOS only)
  - **Android**: Android Studio with Android SDK

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/news_podcast.git
   cd news_podcast
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### iOS Setup

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your development team in Signing & Capabilities
3. Ensure background modes are enabled:
   - Audio, AirPlay, and Picture in Picture
4. Build and run:
   ```bash
   flutter run -d ios
   ```

#### Android Setup

1. Open the project in Android Studio
2. Ensure you have an Android emulator or connected device
3. The app requires minimum SDK 21 (Android 5.0)
4. Build and run:
   ```bash
   flutter run -d android
   ```

#### Web Setup

1. Enable web support:
   ```bash
   flutter config --enable-web
   ```
2. Run on web:
   ```bash
   flutter run -d chrome
   ```

## 📖 Usage Guide

### Basic Navigation

The app has two main tabs:

1. **Podcasts Tab**: Browse available podcasts
   - Tap any podcast to view episodes
   - Tap an episode to start playback
   - Use the audio player controls at the bottom

2. **News Tab**: Read news articles
   - Scroll through the latest articles
   - Tap an article to read the full content
   - Open in browser for full article view

### Voice Commands

The app supports hands-free voice control for podcast playback:

1. **Start Voice Control**: Tap the microphone button in the audio player
2. **Speak Commands**: Use natural language commands like:
   - "Play" or "Resume" - Start/resume playback
   - "Pause" - Pause playback
   - "Skip forward 30 seconds" - Jump ahead
   - "Go back" - Rewind 10 seconds
   - "Restart" - Start from beginning

See [VOICE_COMMANDS.md](VOICE_COMMANDS.md) for the complete list of supported commands.

### Background Playback

- Audio continues playing when you switch apps
- Lock screen controls available on iOS and Android
- Notification shows current episode and artwork
- Swipe down notification for quick controls

## 🛠️ Development

### Project Structure

```
lib/
├── main.dart                 # App entry point and main UI
├── models/                   # Data models
│   ├── podcast.dart
│   ├── podcast_episode.dart
│   └── news_article.dart
├── pages/                    # Screen pages
│   ├── podcast_detail_page.dart
│   ├── news_page.dart
│   └── news_detail_page.dart
├── providers/                # State management
│   └── audio_player_provider.dart
├── utils/                    # Utilities
│   ├── html_parser.dart
│   ├── podcast_scraper.dart
│   ├── news_scraper.dart
│   └── voice_command_parser.dart
└── widgets/                  # Reusable widgets
    └── audio_player_sheet.dart
```

### Key Dependencies

- `just_audio` & `just_audio_background`: Audio playback and background support
- `speech_to_text`: Voice recognition for commands
- `html`: HTML parsing for content scraping
- `http`: Network requests
- `url_launcher`: Opening URLs in browser
- `flutter_svg`: SVG icon support
- `home_widget`: Home screen widgets
- `uni_links`: Deep linking support

### Building for Release

#### Android

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS

```bash
flutter build ios --release
# Then open in Xcode to archive and upload
```

#### Web

```bash
flutter build web --release
```

## 🔧 Configuration

### Customizing Package Name

Before publishing to app stores, update the package name:

1. **Android**: Update `android/app/build.gradle.kts`
   - Change `namespace` and `applicationId` from `com.example.news_podcast` to your own package name
   - Update package references in Kotlin files if needed

2. **iOS**: Update bundle identifier in Xcode
   - Open `ios/Runner.xcworkspace` in Xcode
   - Change Bundle Identifier in Signing & Capabilities

3. **Update widget references**: In `lib/providers/audio_player_provider.dart`, update the `qualifiedAndroidName` to match your new package name

### Customizing the Data Source

The app currently scrapes content from a specific source. To customize:

1. **Podcasts**: Edit `lib/utils/podcast_scraper.dart`
   - Modify `_baseUrl` and scraping logic
   - Update JSON parsing if needed

2. **News**: Edit `lib/utils/news_scraper.dart`
   - Modify `_baseUrl` and `_newsPageUrl`
   - Adjust parsing logic for your source

3. **Local Data**: Use `assets/podcasts.json` as a fallback
   - Format: JSON with a `podcasts` array
   - Each podcast needs: `title`, `href`, `absolute_url`, optional `description` and `image`

### Deep Linking

The app supports deep links for voice commands:
- Scheme: `news://play?topic=<topic>&latest=true`
- Example: `news://play?topic=business&latest=true`

Configure in:
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: Add URL scheme in Xcode project settings

## 🧪 Testing

Run tests with:

```bash
flutter test
```

For widget tests:

```bash
flutter test test/widget_test.dart
```

## 📝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Dart/Flutter style guidelines
- Run `dart format .` before committing
- Ensure `flutter analyze` passes without errors

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Audio playback powered by [just_audio](https://pub.dev/packages/just_audio)
- Voice recognition via [speech_to_text](https://pub.dev/packages/speech_to_text)

## 📞 Support

If you encounter any issues or have questions:

1. Check existing [Issues](https://github.com/yourusername/news_podcast/issues)
2. Create a new issue with:
   - Description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Device/platform information

## 🗺️ Roadmap

- [ ] Phase 2: Google Assistant integration
- [ ] Phase 3: Siri Shortcuts integration
- [ ] AI-powered podcast summaries
- [ ] Transcript generation and search
- [ ] Offline download support
- [ ] Playlist creation
- [ ] Social sharing features

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Voice Commands Guide](VOICE_COMMANDS.md)
- [Changelog](CHANGELOG.md)

---

**Note**: This app scrapes content from public websites. Ensure you comply with the terms of service of any websites you scrape. Consider using official APIs when available.

Made with ❤️ using Flutter
