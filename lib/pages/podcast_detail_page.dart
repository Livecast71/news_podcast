import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/podcast.dart';
import '../models/podcast_episode.dart';
import '../utils/html_parser.dart';
import '../widgets/audio_player_sheet.dart';

class PodcastDetailPage extends StatefulWidget {
  final Podcast podcast;
  final bool autoPlayLatest;

  const PodcastDetailPage({
    super.key,
    required this.podcast,
    this.autoPlayLatest = false,
  });

  @override
  State<PodcastDetailPage> createState() => _PodcastDetailPageState();
}

class _PodcastDetailPageState extends State<PodcastDetailPage> {
  PodcastProgram? _program;
  List<PodcastEpisode> _episodes = [];
  Map<int, Map<String, dynamic>> _episodeRawJson = {}; // Store raw JSON by episode ID
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPodcastData();
  }

  Future<void> _loadPodcastData() async {
    try {
      // Fetch HTML from URL (remove .html extension if present)
      String url = widget.podcast.absoluteUrl;
      if (url.endsWith('.html')) {
        url = url.substring(0, url.length - 5); // Remove .html
      }
      
      debugPrint('Fetching podcast data from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load podcast: HTTP ${response.statusCode}');
      }
      
      final htmlContent = response.body;

      // Parse HTML to extract JSON data
      final pageProps = PodcastHtmlParser.extractPodcastData(htmlContent);
      if (pageProps == null) {
        setState(() {
          _error = 'Could not parse podcast data';
          _loading = false;
        });
        return;
      }

      // Extract program data
      final programJson = pageProps['program'] as Map<String, dynamic>?;
      final episodesJson = pageProps['episodes'] as List<dynamic>? ?? [];

      // Store raw JSON for each episode so we can access fields like 'slug'
      final rawJsonMap = <int, Map<String, dynamic>>{};
      final episodes = <PodcastEpisode>[];
      
      for (final e in episodesJson) {
        final jsonMap = e as Map<String, dynamic>;
        final episode = PodcastEpisode.fromJson(jsonMap);
        if (episode.id > 0) {
          rawJsonMap[episode.id] = jsonMap;
        }
        episodes.add(episode);
      }
      
      setState(() {
        _program = programJson != null
            ? PodcastProgram.fromJson(programJson)
            : null;
        _episodes = episodes;
        _episodeRawJson = rawJsonMap;
        _loading = false;
      });

      // Auto-play latest episode when requested
      if (mounted && widget.autoPlayLatest && _episodes.isNotEmpty) {
        _openPlayerForEpisode(_episodes.first);
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading podcast: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.podcast.absoluteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_program?.title ?? widget.podcast.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in browser',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : CustomScrollView(
                  slivers: [
                    if (_program != null) _buildHeader(_program!),
                    _buildEpisodesList(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error ?? 'Could not load podcast page',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open in Browser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PodcastProgram program) {
    Color programColor = Theme.of(context).colorScheme.primary;
    if (program.programColor != null && program.programColor!.isNotEmpty) {
      try {
        final hexColor = program.programColor!.replaceFirst('#', '');
        if (hexColor.length == 8) {
          // ARGB format: convert to RGBA for Flutter Color
          final r = hexColor.substring(2, 4);
          final g = hexColor.substring(4, 6);
          final b = hexColor.substring(6, 8);
          final a = hexColor.substring(0, 2);
          programColor = Color(int.parse('$a$r$g$b', radix: 16));
        } else if (hexColor.length == 6) {
          // RGB format: add full opacity
          programColor = Color(int.parse('FF$hexColor', radix: 16));
        }
      } catch (e) {
        // Use default color if parsing fails
      }
    }

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              programColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (program.logoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      program.logoUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(width: 120, height: 120),
                    ),
                  ),
                if (program.logoUrl != null) const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (program.intro.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          program.intro,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (program.broadcastSchedule.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: programColor),
                            const SizedBox(width: 8),
                            Text(
                              program.broadcastSchedule,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: programColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesList() {
    if (_episodes.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No episodes available')),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final episode = _episodes[index];
          return _EpisodeCard(
            episode: episode,
            onPlay: () => _openPlayerForEpisode(episode),
          );
        },
        childCount: _episodes.length,
      ),
    );
  }

  void _openPlayerForEpisode(PodcastEpisode episode) {
    final resolved = _resolveEpisodeAudioUrl(episode);
    if (resolved != null && resolved.isNotEmpty) {
      _presentPlayer(resolved, episode);
      return;
    }
    _fetchAndPlayEpisodeAudio(episode);
  }

  String? _resolveEpisodeAudioUrl(PodcastEpisode episode) {
    // The episode already has audios parsed via PodcastEpisode.fromJson
    // Check episode.audios directly (this is already a List<PodcastAudio>)
    if (episode.audios.isNotEmpty) {
      final firstAudio = episode.audios.first;
      if (firstAudio.sourceUrl.isNotEmpty) {
        debugPrint('Found audio URL from episode.audios: ${firstAudio.sourceUrl}');
        return firstAudio.sourceUrl;
      }
    }
    
    // Fallback: Try to access raw JSON if parsing failed
    try {
      final rawJson = _episodeRawJson[episode.id];
      if (rawJson != null) {
        final audiosJson = rawJson['audios'] as List<dynamic>?;
        if (audiosJson != null && audiosJson.isNotEmpty) {
          final first = audiosJson.first as Map<String, dynamic>?;
          final src = first?['sourceUrl'] as String? ?? first?['url'] as String?;
          if (src != null && src.isNotEmpty) {
            debugPrint('Found audio URL from raw JSON: $src');
            return src;
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting audio from raw JSON: $e');
    }
    
    return null;
  }

  Future<void> _fetchAndPlayEpisodeAudio(PodcastEpisode episode) async {
    try {
      final episodeUrl = _resolveEpisodePageUrl(episode);
      String? audioUrl;

      if (episodeUrl != null) {
        final url = episodeUrl.endsWith('.html') ? episodeUrl.substring(0, episodeUrl.length - 5) : episodeUrl;
        debugPrint('Fetching episode page: $url');
        final resp = await http.get(Uri.parse(url), headers: const {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
        });
        debugPrint('Episode page response status: ${resp.statusCode}');
        if (resp.statusCode == 200) {
          audioUrl = _extractFirstAudioSrc(resp.body);
          debugPrint('Extracted audio URL from episode page: ${audioUrl != null ? "yes" : "no"}');
        } else {
          debugPrint('Failed to fetch episode page: HTTP ${resp.statusCode}');
        }
      }

      // Fallback: fetch the program page and try to find any audio tag
      if ((audioUrl == null || audioUrl.isEmpty)) {
        String programUrl = widget.podcast.absoluteUrl;
        if (programUrl.endsWith('.html')) {
          programUrl = programUrl.substring(0, programUrl.length - 5);
        }
        debugPrint('Fetching program page for audio fallback: $programUrl');
        final respProgram = await http.get(Uri.parse(programUrl), headers: const {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
        });
        if (respProgram.statusCode == 200) {
          audioUrl = _extractFirstAudioSrc(respProgram.body);
        }
      }

      if (audioUrl == null || audioUrl.isEmpty) throw Exception('No <audio src> found');
      if (!mounted) return;
      _presentPlayer(audioUrl, episode);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No audio URL found: $e')),
      );
    }
  }

  void _presentPlayer(String audioUrl, PodcastEpisode episode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AudioPlayerSheet(
          audioUrl: audioUrl,
          title: episode.title,
          imageUrl: episode.imageUrl,
        ),
      ),
    );
  }

  String? _resolveEpisodePageUrl(PodcastEpisode episode) {
    try {
      // First try shareUrl which might already have the full URL
      if (episode.shareUrl != null && episode.shareUrl!.isNotEmpty) {
        String url = episode.shareUrl!;
        if (!url.startsWith('http')) {
          // If it's relative, make it absolute
          if (!url.startsWith('/')) url = '/$url';
          url = 'https://www.bnr.nl$url';
        }
        return url;
      }
      
      // Try to access raw JSON fields that might not be in the model
      final rawJson = _episodeRawJson[episode.id];
      
      // Try slug from raw JSON
      final slug = rawJson?['slug'] as String?;
      final urlField = rawJson?['url'] as String?;
      final hrefField = rawJson?['href'] as String?;
      
      if (slug != null && slug.isNotEmpty && episode.id > 0) {
        // Build URL pattern: /podcast/{program-slug}/{episode-id}/{episode-slug}
        final programSlug = _extractProgramSlug(widget.podcast.absoluteUrl);
        if (programSlug != null) {
          return 'https://www.bnr.nl/podcast/$programSlug/${episode.id}/$slug';
        }
      }
      
      // Fallback to other fields
      final candidates = <String?>[urlField, hrefField];
      String? path = candidates.firstWhere(
        (e) => e != null && (e as String).isNotEmpty,
        orElse: () => null,
      );
      
      if (path != null) {
        if (path.startsWith('http')) return path;
        final base = widget.podcast.absoluteUrl.endsWith('/')
            ? widget.podcast.absoluteUrl.substring(0, widget.podcast.absoluteUrl.length - 1)
            : widget.podcast.absoluteUrl;
        if (path.startsWith('/')) path = path.substring(1);
        return '$base/$path';
      }
      
      return null;
    } catch (e) {
      debugPrint('Error resolving episode URL: $e');
      return null;
    }
  }
  
  String? _extractProgramSlug(String absoluteUrl) {
    // Extract slug from URL like: https://www.bnr.nl/podcast/boekestijn-en-de-wijk
    final uri = Uri.parse(absoluteUrl);
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'podcast') {
      return segments[1]; // Returns "boekestijn-en-de-wijk"
    }
    return null;
  }

  String? _extractFirstAudioSrc(String htmlContent) {
    try {
      final doc = html_parser.parse(htmlContent);
      
      // Try multiple selectors for audio tags
      var audio = doc.querySelector('audio[src]');
      if (audio != null) {
        final src = audio.attributes['src'];
        if (src != null && src.isNotEmpty) {
          debugPrint('Found audio src: $src');
          return src;
        }
      }
      
      // Try audio tag without src (might have source child)
      audio = doc.querySelector('audio');
      if (audio != null) {
        final source = audio.querySelector('source[src]');
        if (source != null) {
          final src = source.attributes['src'];
          if (src != null && src.isNotEmpty) {
            debugPrint('Found audio source src: $src');
            return src;
          }
        }
      }
      
      // Look for any element with audio URL pattern (omny.fm)
      final allAudioElements = doc.querySelectorAll('audio, [src*="omny.fm"], [src*="audio.mp3"]');
      for (final element in allAudioElements) {
        final src = element.attributes['src'];
        if (src != null && src.isNotEmpty && (src.contains('omny.fm') || src.endsWith('.mp3'))) {
          debugPrint('Found audio URL in element: $src');
          return src;
        }
      }
      
      // Last resort: search HTML content directly for omny.fm audio URLs
      // Match URLs like https://...omny.fm/.../audio.mp3
      final regex = RegExp(r'https?://[^\s"<>]+omny\.fm[^\s"<>]+audio\.mp3');
      final match = regex.firstMatch(htmlContent);
      if (match != null) {
        final url = match.group(0);
        debugPrint('Found audio URL via regex: $url');
        return url;
      }
      
      debugPrint('No audio URL found in HTML');
      return null;
    } catch (e) {
      debugPrint('Error extracting audio src: $e');
      return null;
    }
  }
}

class _EpisodeCard extends StatelessWidget {
  final PodcastEpisode episode;
  final VoidCallback onPlay;

  const _EpisodeCard({required this.episode, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (episode.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        episode.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(width: 80, height: 80),
                      ),
                    ),
                  if (episode.imageUrl != null) const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (episode.publicationDate.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            episode.publicationDate,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                        if (episode.audios.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.play_circle_outline,
                                  size: 18, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                episode.audios.first.durationFormatted,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (episode.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  episode.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
