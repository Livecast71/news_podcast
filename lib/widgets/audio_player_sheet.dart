import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../utils/voice_command_parser.dart';
import '../providers/audio_player_provider.dart';

class AudioPlayerSheet extends StatefulWidget {
  final String audioUrl;
  final String title;
  final String? imageUrl;

  const AudioPlayerSheet({
    super.key,
    required this.audioUrl,
    required this.title,
    this.imageUrl,
  });

  @override
  State<AudioPlayerSheet> createState() => _AudioPlayerSheetState();
}

class _AudioPlayerSheetState extends State<AudioPlayerSheet> {
  final AudioPlayer _player = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastCommand = '';
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _init();
    _initSpeech();
    _setupPlaybackListener();
  }

  void _setupPlaybackListener() {
    _player.playerStateStream.listen((state) async {
      final audioProvider = AudioPlayerProvider();
      await audioProvider.updateNowPlaying(
        podcastTitle: null,
        episodeTitle: widget.title,
        artworkUrl: widget.imageUrl,
        isPlaying: state.playing,
      );
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );
    setState(() {});
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    try {
      // Use AudioSource with metadata for background playback
      final audioSource = AudioSource.uri(
        Uri.parse(widget.audioUrl),
        tag: MediaItem(
          id: widget.audioUrl,
          title: widget.title,
          artUri: widget.imageUrl != null ? Uri.parse(widget.imageUrl!) : null,
        ),
      );
      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (_) {
      // Show error UI via SnackBar but avoid throwing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start playback')),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for voice commands')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _processVoiceCommand(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _processVoiceCommand(String spokenText) async {
    final command = VoiceCommandParser.parse(spokenText);
    final description = VoiceCommandParser.getDescription(command);
    
    setState(() => _lastCommand = description);

    // Execute the command
    switch (command.type) {
      case VoiceCommandType.play:
        await _player.play();
        break;
      case VoiceCommandType.pause:
        await _player.pause();
        break;
      case VoiceCommandType.stop:
        await _player.stop();
        break;
      case VoiceCommandType.skipForward:
        final pos = await _player.position;
        await _player.seek(pos + (command.skipDuration ?? const Duration(seconds: 30)));
        break;
      case VoiceCommandType.skipBackward:
        final pos = await _player.position;
        await _player.seek(pos - (command.skipDuration ?? const Duration(seconds: 10)));
        break;
      case VoiceCommandType.restart:
        await _player.seek(Duration.zero);
        break;
      case VoiceCommandType.unknown:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Command not recognized: "$spokenText"')),
          );
        }
        break;
    }

    // Clear the command text after 2 seconds
    if (command.type != VoiceCommandType.unknown) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _lastCommand = '');
        }
      });
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (widget.imageUrl != null) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<Duration?>(
              stream: _player.durationStream,
              builder: (context, snapshot) {
                final total = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  initialData: Duration.zero,
                  builder: (context, snap) {
                    final pos = snap.data ?? Duration.zero;
                    return Column(
                      children: [
                        Slider(
                          value: pos.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                          max: (total.inMilliseconds > 0 ? total.inMilliseconds : 1).toDouble(),
                          onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_format(pos), style: theme.textTheme.bodySmall),
                            Text(_format(total), style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            // Voice command feedback
            if (_lastCommand.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _lastCommand,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Center(
              child: StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.replay_10),
                        onPressed: () async {
                          final p = await _player.position;
                          await _player.seek(p - const Duration(seconds: 10));
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        label: Text(playing ? 'Pause' : 'Play'),
                        onPressed: () => playing ? _player.pause() : _player.play(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.forward_10),
                        onPressed: () async {
                          final p = await _player.position;
                          await _player.seek(p + const Duration(seconds: 10));
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Voice control button
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ]
                      : null,
                ),
                child: Material(
                  color: _isListening
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  shape: const CircleBorder(),
                  elevation: _isListening ? 8 : 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _speechAvailable
                        ? (_isListening ? _stopListening : _startListening)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 32,
                        color: _isListening
                            ? theme.colorScheme.onPrimary
                            : (_speechAvailable
                                ? theme.colorScheme.primary
                                : theme.disabledColor),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isListening
                    ? 'Listening... Say "play", "pause", "skip forward", etc.'
                    : 'Tap mic for voice commands',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


