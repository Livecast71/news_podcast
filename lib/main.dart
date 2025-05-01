import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:home_widget/home_widget.dart';

import 'models/podcast.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'pages/podcast_detail_page.dart';
import 'pages/news_page.dart';
import 'utils/podcast_scraper.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

/// Called when doing background work initiated from Widget
@pragma("vm:entry-point")
Future<void> interactiveCallback(Uri? data) async {
  // Handle widget button clicks here
  debugPrint('Widget interaction: ${data?.toString()}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.news.podcast.playback',
    androidNotificationChannelName: 'Podcast Playback',
    androidNotificationOngoing: true,
  );
  HomeWidget.setAppGroupId('group.com.news.podcast');
  HomeWidget.registerInteractivityCallback(interactiveCallback);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Podcast',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ).copyWith(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          surface: const Color(0xFF121212),
          background: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.amber,
          elevation: 0,
        ),
        cardColor: const Color(0xFF1A1A1A),
        dividerColor: const Color(0x22FFFFFF),
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.amber,
          textColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          subtitleTextStyle: TextStyle(
            color: Color(0xFFBDBDBD),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.amber,
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to update icon colors
    });

    // Handle deep link on cold start
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialUri());
    // Handle deep links while app is running
    _sub = uriLinkStream.listen((uri) {
      if (!mounted || uri == null) return;
      _handleVoiceUri(uri);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      if (uri != null) _handleVoiceUri(uri);
    } catch (_) {}
  }

  Future<void> _handleVoiceUri(Uri uri) async {
    // Expecting scheme news://play?topic=...&latest=true
    if (uri.scheme != 'news' || uri.host != 'play') return;

    final topic = uri.queryParameters['topic']?.toLowerCase().trim();
    final latest = (uri.queryParameters['latest'] ?? 'true').toLowerCase() == 'true';
    if (!latest) return;

    // Load podcasts (scrape or from assets) like PodcastsPage does
    List<Podcast> podcasts;
    try {
      final scraped = await PodcastScraper.scrapePodcasts();
      podcasts = scraped.isNotEmpty ? scraped : await _loadLocalPodcasts();
    } catch (_) {
      podcasts = await _loadLocalPodcasts();
    }

    // Find first podcast whose title contains topic; if none, fallback to first
    Podcast? match;
    if (topic != null && topic.isNotEmpty) {
      match = podcasts.firstWhere(
        (p) => p.title.toLowerCase().contains(topic),
        orElse: () => podcasts.isNotEmpty ? podcasts.first : null as Podcast,
      );
    }
    match ??= podcasts.isNotEmpty ? podcasts.first : null;
    if (match == null) return;

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PodcastDetailPage(podcast: match!, autoPlayLatest: true),
      ),
    );
  }

  Future<List<Podcast>> _loadLocalPodcasts() async {
    final assetPath = kIsWeb ? 'podcasts.json' : 'assets/podcasts.json';
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final list = (decoded['podcasts'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Podcast.fromJson)
        .toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Podcast'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PodcastsPage(),
          NewsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Color(0x22FFFFFF), width: 1),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _tabController.animateTo(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/svg/radio.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              _tabController.index == 0
                                  ? Colors.amber
                                  : Colors.grey,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Podcasts',
                            style: TextStyle(
                              color: _tabController.index == 0
                                  ? Colors.amber
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _tabController.animateTo(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/svg/news.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              _tabController.index == 1
                                  ? Colors.amber
                                  : Colors.grey,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'News',
                            style: TextStyle(
                              color: _tabController.index == 1
                                  ? Colors.amber
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PodcastsPage extends StatefulWidget {
  const PodcastsPage({super.key});

  @override
  State<PodcastsPage> createState() => _PodcastsPageState();
}

class _PodcastsPageState extends State<PodcastsPage> {
  late final Future<List<Podcast>> _podcastsFuture = _loadPodcasts();

  Future<List<Podcast>> _loadPodcasts() async {
    try {
      // Try to scrape podcasts from the source
      debugPrint('Scraping podcasts...');
      final scraped = await PodcastScraper.scrapePodcasts();
      if (scraped.isNotEmpty) {
        debugPrint('Successfully scraped ${scraped.length} podcasts');
        return scraped;
      }
    } catch (e) {
      debugPrint('Scraping failed, falling back to local JSON: $e');
    }
    
    // Fallback to local JSON file
    try {
      final assetPath = kIsWeb ? 'podcasts.json' : 'assets/podcasts.json';
      final raw = await rootBundle.loadString(assetPath);
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final list = (decoded['podcasts'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(Podcast.fromJson)
          .toList();
      debugPrint('Loaded ${list.length} podcasts from local JSON');
      return list;
    } catch (e) {
      debugPrint('Error loading local JSON: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcasts'),
      ),
      body: FutureBuilder<List<Podcast>>(
        future: _podcastsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final items = (snapshot.data ?? const <Podcast>[])
              .where((p) => !p.title.toLowerCase().contains('filtercontainer_inner'))
              .toList();
          if (items.isEmpty) {
            return const Center(child: Text('No podcasts found'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = items[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _PodcastImage(url: p.imageUrl),
                title: Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: p.description == null || p.description!.isEmpty
                    ? null
                    : Text(
                        p.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PodcastDetailPage(podcast: p),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PodcastImage extends StatelessWidget {
  final String? url;
  const _PodcastImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final resolved = url;
    if (resolved == null || resolved.isEmpty) {
      return const SizedBox(width: 56, height: 56);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        resolved,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(width: 56, height: 56),
      ),
    );
  }
}
