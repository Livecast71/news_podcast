class VoiceCommand {
  final VoiceCommandType type;
  final String? searchQuery;
  final Duration? skipDuration;

  VoiceCommand({
    required this.type,
    this.searchQuery,
    this.skipDuration,
  });
}

enum VoiceCommandType {
  play,
  pause,
  stop,
  skipForward,
  skipBackward,
  restart,
  unknown,
}

class VoiceCommandParser {
  /// Parse a spoken text string into a voice command
  static VoiceCommand parse(String spokenText) {
    final text = spokenText.toLowerCase().trim();

    // Play commands
    if (_matchesAny(text, ['play', 'start', 'resume', 'continue'])) {
      return VoiceCommand(type: VoiceCommandType.play);
    }

    // Pause commands
    if (_matchesAny(text, ['pause', 'hold', 'wait', 'stop playing'])) {
      return VoiceCommand(type: VoiceCommandType.pause);
    }

    // Stop commands
    if (_matchesAny(text, ['stop', 'end'])) {
      return VoiceCommand(type: VoiceCommandType.stop);
    }

    // Skip forward commands
    if (_containsAny(text, [
      'skip forward',
      'skip ahead',
      'forward',
      'fast forward',
      'next',
      'skip',
    ])) {
      final duration = _extractDuration(text) ?? const Duration(seconds: 30);
      return VoiceCommand(
        type: VoiceCommandType.skipForward,
        skipDuration: duration,
      );
    }

    // Skip backward commands
    if (_containsAny(text, [
      'skip backward',
      'skip back',
      'go back',
      'backward',
      'rewind',
      'back',
      'previous',
    ])) {
      final duration = _extractDuration(text) ?? const Duration(seconds: 10);
      return VoiceCommand(
        type: VoiceCommandType.skipBackward,
        skipDuration: duration,
      );
    }

    // Restart commands
    if (_matchesAny(text, [
      'restart',
      'start over',
      'from the beginning',
      'beginning',
    ])) {
      return VoiceCommand(type: VoiceCommandType.restart);
    }

    // Unknown command
    return VoiceCommand(type: VoiceCommandType.unknown);
  }

  /// Check if text matches any of the patterns exactly
  static bool _matchesAny(String text, List<String> patterns) {
    return patterns.any((pattern) => text == pattern);
  }

  /// Check if text contains any of the patterns
  static bool _containsAny(String text, List<String> patterns) {
    return patterns.any((pattern) => text.contains(pattern));
  }

  /// Extract duration from text like "30 seconds" or "2 minutes"
  static Duration? _extractDuration(String text) {
    // Match patterns like "30 seconds", "2 minutes", "1 minute"
    final secondsMatch = RegExp(r'(\d+)\s*(?:second|sec)').firstMatch(text);
    if (secondsMatch != null) {
      final seconds = int.tryParse(secondsMatch.group(1) ?? '');
      if (seconds != null) return Duration(seconds: seconds);
    }

    final minutesMatch = RegExp(r'(\d+)\s*(?:minute|min)').firstMatch(text);
    if (minutesMatch != null) {
      final minutes = int.tryParse(minutesMatch.group(1) ?? '');
      if (minutes != null) return Duration(minutes: minutes);
    }

    return null;
  }

  /// Get a user-friendly description of the command
  static String getDescription(VoiceCommand command) {
    switch (command.type) {
      case VoiceCommandType.play:
        return 'Playing';
      case VoiceCommandType.pause:
        return 'Paused';
      case VoiceCommandType.stop:
        return 'Stopped';
      case VoiceCommandType.skipForward:
        final secs = command.skipDuration?.inSeconds ?? 30;
        return 'Skipped forward $secs seconds';
      case VoiceCommandType.skipBackward:
        final secs = command.skipDuration?.inSeconds ?? 10;
        return 'Skipped back $secs seconds';
      case VoiceCommandType.restart:
        return 'Restarted from beginning';
      case VoiceCommandType.unknown:
        return 'Command not recognized';
    }
  }
}


