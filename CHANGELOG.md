# Changelog

## [Unreleased] - 2025-05-01

### 🎤 Added - Voice Commands (Phase 1)
- **In-app voice control** for hands-free podcast playback
- Microphone button in audio player for voice commands
- Support for commands: play, pause, stop, skip forward/backward, restart
- Intelligent parsing of time-based commands ("skip forward 30 seconds")
- Visual feedback when listening and command confirmation
- Automatic microphone permission handling for iOS and Android
- Voice command guide documentation (`VOICE_COMMANDS.md`)

### 🔊 Added - Background Audio Playback
- Audio continues playing when app goes to background
- Lock screen media controls on both iOS and Android
- Notification with podcast title and artwork
- Proper audio session configuration for music playback
- iOS background audio mode enabled
- Android foreground service for media playback

### 🛠️ Technical Changes
- Added `just_audio_background` dependency for media notifications
- Added `speech_to_text` for voice recognition
- Added `permission_handler` for runtime permissions
- Updated iOS `Info.plist` with background modes and microphone permissions
- Updated Android manifest with media service and audio permissions
- Fixed iOS Swift bridging header issue in Podfile
- Created `VoiceCommandParser` utility for natural language processing

### 📝 Files Modified
- `pubspec.yaml` - Added new dependencies
- `lib/main.dart` - Initialized background audio service
- `lib/widgets/audio_player_sheet.dart` - Added voice control UI and logic
- `lib/utils/voice_command_parser.dart` - New voice command parser
- `ios/Runner/Info.plist` - Background audio + microphone permissions
- `ios/Podfile` - Swift configuration for speech_to_text
- `android/app/src/main/AndroidManifest.xml` - Media service + permissions

### 🚀 Coming Soon
- Phase 2: Google Assistant integration ("Hey Google" commands)
- Phase 3: Siri Shortcuts integration ("Hey Siri" commands)
- AI-powered podcast summaries
- Transcript generation and search

