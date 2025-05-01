import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/news_article.dart';

class NewsScraper {
  static const String _baseUrl = 'https://www.bnr.nl';
  static const String _newsPageUrl = '$_baseUrl/nieuws';

  static Future<List<NewsArticle>> scrapeNews() async {
    try {
      final response = await http.get(
        Uri.parse(_newsPageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load news page: HTTP ${response.statusCode}');
      }

      final htmlContent = response.body;

      // Try to extract JSON data from __NEXT_DATA__ script tag
      final jsonData = _extractJsonData(htmlContent);
      if (jsonData != null) {
        final articles = _parseNewsFromJson(jsonData);
        if (articles.isNotEmpty) {
          return articles;
        }
      }

      // Fallback: Try to parse HTML directly
      return _parseNewsFromHtml(htmlContent);
    } catch (e) {
      throw Exception('Error scraping news: $e');
    }
  }

  /// Extracts JSON data from __NEXT_DATA__ script tag
  static Map<String, dynamic>? _extractJsonData(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);
      final scriptTags = document.querySelectorAll('script#__NEXT_DATA__');

      if (scriptTags.isEmpty) {
        return null;
      }

      final scriptContent = scriptTags.first.text;
      final jsonData = json.decode(scriptContent) as Map<String, dynamic>;
      return jsonData;
    } catch (e) {
      return null;
    }
  }

  /// Parses news articles from JSON data structure
  static List<NewsArticle> _parseNewsFromJson(Map<String, dynamic> jsonData) {
    try {
      final props = jsonData['props'] as Map<String, dynamic>?;
      if (props == null) return [];

      final pageProps = props['pageProps'] as Map<String, dynamic>?;
      if (pageProps == null) return [];

      final articles = <NewsArticle>[];

      // Try different possible JSON structures for news
      if (pageProps.containsKey('articles')) {
        final articlesList = pageProps['articles'] as List<dynamic>?;
        if (articlesList != null) {
          for (final item in articlesList) {
            // Check if this item has HorizontalCard4_article in its structure
            final itemMap = item as Map<String, dynamic>;
            final className = itemMap['className'] as String? ?? 
                            itemMap['class'] as String? ?? 
                            itemMap['componentType'] as String? ?? '';
            if (className.toLowerCase().contains('horizontalcard4_article')) {
              final article = _parseSingleArticle(item);
              if (article != null) articles.add(article);
            }
          }
        }
      }

      // Try alternative structure
      if (articles.isEmpty && pageProps.containsKey('news')) {
        final newsList = pageProps['news'] as List<dynamic>?;
        if (newsList != null) {
          for (final item in newsList) {
            // Check if this item has HorizontalCard4_article in its structure
            final itemMap = item as Map<String, dynamic>;
            final className = itemMap['className'] as String? ?? 
                            itemMap['class'] as String? ?? 
                            itemMap['componentType'] as String? ?? '';
            if (className.toLowerCase().contains('horizontalcard4_article')) {
              final article = _parseSingleArticle(item);
              if (article != null) articles.add(article);
            }
          }
        }
      }

      // Try items or data structure
      if (articles.isEmpty && pageProps.containsKey('items')) {
        final itemsList = pageProps['items'] as List<dynamic>?;
        if (itemsList != null) {
          for (final item in itemsList) {
            // Check if this item has HorizontalCard4_article in its structure
            final itemMap = item as Map<String, dynamic>;
            final className = itemMap['className'] as String? ?? 
                            itemMap['class'] as String? ?? 
                            itemMap['componentType'] as String? ?? '';
            if (className.toLowerCase().contains('horizontalcard4_article')) {
              final article = _parseSingleArticle(item);
              if (article != null) articles.add(article);
            }
          }
        }
      }

      // Filter to only include items that match HorizontalCard4_article
      // Since we're already filtering at parsing, this is a final safeguard
      return articles;
    } catch (e) {
      return [];
    }
  }

  /// Parses a single news article from JSON
  static NewsArticle? _parseSingleArticle(dynamic item) {
    try {
      final map = item as Map<String, dynamic>;

      final title = map['title'] as String? ?? '';
      final slug = map['slug'] as String? ?? map['url'] as String? ?? '';
      final description = map['description'] as String? ?? map['teaser'] as String? ?? map['intro'] as String?;
      final imageUrl = map['image'] as String? ?? map['imageUrl'] as String?;
      final imagePath = map['img']?['path'] as String?;
      final publicationDate = map['publicationDate'] as String? ?? map['date'] as String?;
      final category = map['category'] as String? ?? map['categoryTitle'] as String?;

      // Filter out unwanted items
      if (title.isEmpty || 
          title.toLowerCase().contains('filtercontainer_inner') ||
          (slug.isNotEmpty && slug.toLowerCase().contains('filtercontainer_inner'))) {
        return null;
      }

      // Build URLs
      String href;
      if (slug.isNotEmpty) {
        href = slug.startsWith('/') ? slug.substring(1) : slug;
      } else {
        final id = map['id'] as int? ?? map['id'] as String?;
        if (id != null) {
          href = 'nieuws/article/$id';
        } else {
          return null;
        }
      }

      String absoluteUrl = '$_baseUrl/$href';
      if (absoluteUrl.endsWith('.html')) {
        absoluteUrl = absoluteUrl.substring(0, absoluteUrl.length - 5);
      }

      // Handle image URL
      String? finalImageUrl = imageUrl;
      if (finalImageUrl == null && imagePath != null) {
        finalImageUrl = 'https://bnr-external-prod.imgix.net/$imagePath';
      }

      return NewsArticle(
        title: title,
        href: href,
        absoluteUrl: absoluteUrl,
        description: description,
        imageUrl: finalImageUrl,
        publicationDate: publicationDate,
        category: category,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fallback: Parses news articles from HTML DOM
  static List<NewsArticle> _parseNewsFromHtml(String htmlContent) {
    final articles = <NewsArticle>[];

    try {
      final document = html_parser.parse(htmlContent);

      // Only look for links within HorizontalCard4_article elements
      final cardContainers = document.querySelectorAll('[class*="HorizontalCard4_article"]');
      
      // If no HorizontalCard4_article containers found, return empty list
      if (cardContainers.isEmpty) {
        return articles;
      }
      
      // Look for news article links within HorizontalCard4_article containers
      final links = <Element>[];
      for (final container in cardContainers) {
        final containerLinks = container.querySelectorAll('a[href*="/nieuws/"]');
        links.addAll(containerLinks);
      }

      for (final link in links) {
        final href = link.attributes['href'];
        if (href == null || !href.contains('/nieuws/')) continue;

        final absoluteUrl = href.startsWith('/') ? '$_baseUrl$href' : href;
        final relativeHref = href.startsWith('/') ? href.substring(1) : href;

        // Extract title
        final titleElement = link.querySelector('h2, h3, .title, [class*="title"]') ?? link;
        final title = titleElement.text.trim();
        if (title.isEmpty || title.toLowerCase().contains('filtercontainer_inner')) continue;

        // Try to find description and image in parent elements
        Element? parent = link.parent;
        String? description;
        String? imageUrl;
        String? publicationDate;

        // Try to find article parent
        while (parent != null && parent.parent != null) {
          final tagName = parent.localName?.toLowerCase() ?? '';
          final classes = parent.className ?? '';
          if (tagName == 'article' || 
              classes.contains('article') || 
              classes.contains('card') || 
              classes.contains('item')) {
            break;
          }
          parent = parent.parent;
        }

        if (parent != null) {
          final descElement = parent.querySelector('p, .description, [class*="description"], [class*="teaser"]');
          description = descElement?.text.trim();

          final imgElement = parent.querySelector('img');
          imageUrl = imgElement?.attributes['src'] ?? 
                     imgElement?.attributes['data-src'] ??
                     imgElement?.attributes['data-lazy-src'];

          final dateElement = parent.querySelector('time, .date, [class*="date"]');
          publicationDate = dateElement?.attributes['datetime'] ?? dateElement?.text.trim();
        }

        // Remove .html extension if present
        String cleanUrl = absoluteUrl;
        if (cleanUrl.endsWith('.html')) {
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - 5);
        }

        articles.add(NewsArticle(
          title: title,
          href: relativeHref,
          absoluteUrl: cleanUrl,
          description: description,
          imageUrl: imageUrl,
          publicationDate: publicationDate,
        ));
      }
    } catch (e) {
      // If HTML parsing fails, return empty list
    }

    return articles;
  }
}

