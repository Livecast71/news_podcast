import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AudioPlayerState {
  final String? podcastTitle;
  final String? episodeTitle;
  final String? artworkPath;
  final bool isPlaying;

  AudioPlayerState({
    this.podcastTitle,
    this.episodeTitle,
    this.artworkPath,
    this.isPlaying = false,
  });
}

class AudioPlayerProvider extends ChangeNotifier {
  static final AudioPlayerProvider _instance = AudioPlayerProvider._internal();
  factory AudioPlayerProvider() => _instance;
  AudioPlayerProvider._internal();

  AudioPlayerState? _currentState;

  AudioPlayerState? get currentState => _currentState;
  bool get isPlaying => _currentState?.isPlaying ?? false;

  Future<void> updateNowPlaying({
    String? podcastTitle,
    String? episodeTitle,
    String? artworkUrl,
    bool isPlaying = false,
  }) async {
    _currentState = AudioPlayerState(
      podcastTitle: podcastTitle,
      episodeTitle: episodeTitle,
      artworkPath: artworkUrl,
      isPlaying: isPlaying,
    );

    // Update widget
    if (!kIsWeb && Platform.isAndroid) {
      try {
        String? localArtworkPath;
        if (artworkUrl != null && artworkUrl.isNotEmpty) {
          localArtworkPath = await _downloadAndCacheImage(artworkUrl);
        }

        await Future.wait([
          if (podcastTitle != null)
            HomeWidget.saveWidgetData<String>('podcast_title', podcastTitle),
          if (episodeTitle != null)
            HomeWidget.saveWidgetData<String>('episode_title', episodeTitle),
          if (localArtworkPath != null)
            HomeWidget.saveWidgetData<String>('artwork_path', localArtworkPath),
          HomeWidget.saveWidgetData<bool>('is_playing', isPlaying),
        ]);

        await HomeWidget.updateWidget(
          qualifiedAndroidName: 'com.example.news_podcast.PodcastWidgetProvider',
        );
      } catch (e) {
        debugPrint('Error updating widget: $e');
      }
    }

    notifyListeners();
  }

  Future<String?> _downloadAndCacheImage(String url) async {
    try {
      // Get cache directory
      final Directory cacheDir = await getTemporaryDirectory();
      final String filename = Uri.parse(url).pathSegments.last;
      
      // Create filename if needed
      String sanitizedFilename = filename;
      if (sanitizedFilename.isEmpty || !sanitizedFilename.contains('.')) {
        sanitizedFilename = 'widget_artwork_${DateTime.now().millisecondsSinceEpoch}.png';
      }
      
      final File imageFile = File('${cacheDir.path}/$sanitizedFilename');
      
      // Check if already cached
      if (await imageFile.exists()) {
        return imageFile.path;
      }
      
      // Download image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await imageFile.writeAsBytes(response.bodyBytes);
        return imageFile.path;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
  }

  Future<void> clearNowPlaying() async {
    _currentState = null;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await Future.wait([
          HomeWidget.saveWidgetData<String>('podcast_title', null),
          HomeWidget.saveWidgetData<String>('episode_title', null),
          HomeWidget.saveWidgetData<String>('artwork_path', null),
          HomeWidget.saveWidgetData<bool>('is_playing', false),
        ]);

        await HomeWidget.updateWidget(
          qualifiedAndroidName: 'com.example.news_podcast.PodcastWidgetProvider',
        );
      } catch (e) {
        debugPrint('Error clearing widget: $e');
      }
    }

    notifyListeners();
  }
}

