import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/news_article.dart';
import '../utils/html_parser.dart';

class NewsDetailPage extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailPage({
    super.key,
    required this.article,
  });

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  String? _content;
  String? _author;
  List<String> _images = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNewsArticle();
  }

  String _stripHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    try {
      final doc = html_parser.parse(html);
      return doc.body?.text.trim() ?? html.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    } catch (_) {
      return html.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    }
  }

  Future<void> _loadNewsArticle() async {
    try {
      // Fetch HTML from URL (remove .html extension if present)
      String url = widget.article.absoluteUrl;
      if (url.endsWith('.html')) {
        url = url.substring(0, url.length - 5);
      }

      debugPrint('Fetching news article from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load article: HTTP ${response.statusCode}');
      }

      final htmlContent = response.body;

      // Parse HTML to extract JSON data
      final jsonData = PodcastHtmlParser.parseJsonData(htmlContent);
      if (jsonData != null) {
        try {
          final props = jsonData['props'] as Map<String, dynamic>?;
          final pageProps = props?['pageProps'] as Map<String, dynamic>?;

          if (pageProps != null) {
            // Extract article data - check multiple possible structures
            Map<String, dynamic>? articleData;
            
            // Try different keys
            if (pageProps.containsKey('article') && pageProps['article'] is Map<String, dynamic>) {
              articleData = pageProps['article'] as Map<String, dynamic>?;
            } else if (pageProps.containsKey('item') && pageProps['item'] is Map<String, dynamic>) {
              articleData = pageProps['item'] as Map<String, dynamic>?;
            } else if (pageProps.containsKey('newsArticle') && pageProps['newsArticle'] is Map<String, dynamic>) {
              articleData = pageProps['newsArticle'] as Map<String, dynamic>?;
            }

            if (articleData != null) {
              // Safely extract content
              String? content;
              if (articleData.containsKey('content') && articleData['content'] is String) {
                content = articleData['content'] as String?;
              } else if (articleData.containsKey('body') && articleData['body'] is String) {
                content = articleData['body'] as String?;
              } else if (articleData.containsKey('text') && articleData['text'] is String) {
                content = articleData['text'] as String?;
              }

              // Safely extract author
              String? author;
              if (articleData.containsKey('author') && articleData['author'] is String) {
                author = articleData['author'] as String?;
              } else if (articleData.containsKey('authorName') && articleData['authorName'] is String) {
                author = articleData['authorName'] as String?;
              }

              // Safely extract image
              String? image;
              if (articleData.containsKey('image') && articleData['image'] is String) {
                image = articleData['image'] as String?;
              } else if (articleData.containsKey('imageUrl') && articleData['imageUrl'] is String) {
                image = articleData['imageUrl'] as String?;
              }

              // Safely extract image path
              String? imagePath;
              if (articleData.containsKey('img') && articleData['img'] is Map) {
                final imgMap = articleData['img'] as Map<String, dynamic>?;
                if (imgMap != null && imgMap.containsKey('path') && imgMap['path'] is String) {
                  imagePath = imgMap['path'] as String?;
                }
              }

              setState(() {
                _content = _stripHtml(content);
                _author = author;
                if (image != null) {
                  _images = [image];
                } else if (imagePath != null) {
                  _images = ['https://bnr-external-prod.imgix.net/$imagePath'];
                }
                _loading = false;
              });
              return;
            }
          }
        } catch (e) {
          debugPrint('Error parsing JSON structure: $e');
          // Fall through to HTML parsing
        }
      }

      // Fallback: Parse HTML directly
      _parseContentFromHtml(htmlContent);
    } catch (e) {
      setState(() {
        _error = 'Error loading article: $e';
        _loading = false;
      });
    }
  }

  void _parseContentFromHtml(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);

      // Try to find article content
      final contentSelectors = [
        'article .content',
        'article .article-body',
        'article .body',
        '[class*="article-content"]',
        '[class*="article-body"]',
        'main article',
      ];

      String? content;
      for (final selector in contentSelectors) {
        final element = document.querySelector(selector);
        if (element != null) {
          content = element.text.trim();
          if (content.isNotEmpty) break;
        }
      }

      // Extract images
      final imageElements = document.querySelectorAll('article img, [class*="article"] img');
      final images = <String>[];
      for (final img in imageElements) {
        final src = img.attributes['src'] ??
                    img.attributes['data-src'] ??
                    img.attributes['data-lazy-src'];
        if (src != null && src.isNotEmpty && !src.contains('data:')) {
          if (!src.startsWith('http')) {
            images.add('https://www.bnr.nl$src');
          } else {
            images.add(src);
          }
        }
      }

      // Extract author
      final authorSelectors = [
        '[class*="author"]',
        '.byline',
        '[class*="byline"]',
      ];
      String? author;
      for (final selector in authorSelectors) {
        final element = document.querySelector(selector);
        if (element != null) {
          author = element.text.trim();
          if (author.isNotEmpty) break;
        }
      }

      setState(() {
        _content = _stripHtml(content);
        _author = author;
        _images = images;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error parsing article: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _loadNewsArticle();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // Header image
        if (widget.article.imageUrl != null || _images.isNotEmpty)
          SliverToBoxAdapter(
            child: Image.network(
              widget.article.imageUrl ?? _images.first,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),

        // Article content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                if (widget.article.category != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      widget.article.category!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Title
                Text(
                  widget.article.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),

                const SizedBox(height: 16),

                // Meta info
                Row(
                  children: [
                    if (widget.article.publicationDate != null)
                      Text(
                        widget.article.publicationDate!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    if (_author != null) ...[
                      if (widget.article.publicationDate != null)
                        Text(
                          ' • ',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      Text(
                        _author!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Content
                if (_content != null && _content!.isNotEmpty)
                  Text(
                    _content!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: Colors.white,
                        ),
                  )
                else if (widget.article.description != null)
                  Text(
                    widget.article.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: Colors.white,
                        ),
                  ),

                // Additional images
                if (_images.length > 1) ...[
                  const SizedBox(height: 24),
                  ..._images.skip(1).map((imageUrl) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

