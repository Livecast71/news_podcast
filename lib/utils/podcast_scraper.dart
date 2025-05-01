import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../models/podcast.dart';

class PodcastScraper {
  static const String _baseUrl = 'https://www.bnr.nl';
  
  /// Fetches the list of podcasts from BNR.nl podcast page
  static Future<List<Podcast>> scrapePodcasts() async {
    try {
      // Try to fetch from the main podcast listing page
      final response = await http.get(
        Uri.parse('$_baseUrl/podcasts'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load podcasts page: HTTP ${response.statusCode}');
      }
      
      final htmlContent = response.body;
      
      // Try to extract JSON data from __NEXT_DATA__ script tag
      final jsonData = _extractJsonData(htmlContent);
      if (jsonData != null) {
        final podcasts = _parsePodcastsFromJson(jsonData);
        if (podcasts.isNotEmpty) {
          return podcasts;
        }
      }
      
      // Fallback: Try to parse HTML directly
      return _parsePodcastsFromHtml(htmlContent);
    } catch (e) {
      throw Exception('Error scraping podcasts: $e');
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
  
  /// Parses podcasts from JSON data structure
  static List<Podcast> _parsePodcastsFromJson(Map<String, dynamic> jsonData) {
    try {
      final props = jsonData['props'] as Map<String, dynamic>?;
      if (props == null) return [];
      
      final pageProps = props['pageProps'] as Map<String, dynamic>?;
      if (pageProps == null) return [];
      
      // Look for podcast list in various possible locations
      final podcasts = <Podcast>[];
      
      // Try different possible JSON structures
      if (pageProps.containsKey('podcasts')) {
        final podcastsList = pageProps['podcasts'] as List<dynamic>?;
        if (podcastsList != null) {
          for (final item in podcastsList) {
            // Check if this item has HorizontalCard4_article in its structure
            final itemMap = item as Map<String, dynamic>;
            final className = itemMap['className'] as String? ?? 
                            itemMap['class'] as String? ?? 
                            itemMap['componentType'] as String? ?? '';
            if (className.toLowerCase().contains('horizontalcard4_article')) {
              final podcast = _parseSinglePodcast(item);
              if (podcast != null) podcasts.add(podcast);
            }
          }
        }
      }
      
      // Try alternative structure
      if (podcasts.isEmpty && pageProps.containsKey('programs')) {
        final programs = pageProps['programs'] as List<dynamic>?;
        if (programs != null) {
          for (final item in programs) {
            // Check if this item has HorizontalCard4_article in its structure
            final itemMap = item as Map<String, dynamic>;
            final className = itemMap['className'] as String? ?? 
                            itemMap['class'] as String? ?? 
                            itemMap['componentType'] as String? ?? '';
            if (className.toLowerCase().contains('horizontalcard4_article')) {
              final podcast = _parseSinglePodcast(item);
              if (podcast != null) podcasts.add(podcast);
            }
          }
        }
      }
      
      // Filter to only include items that match HorizontalCard4_article
      return podcasts.where((p) {
        // Check if any part of the podcast data suggests it's a HorizontalCard4_article
        // This is a safeguard in case JSON structure doesn't have the class info
        return true; // We'll rely on HTML parsing or URL structure filtering
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Parses a single podcast from JSON
  static Podcast? _parseSinglePodcast(dynamic item) {
    try {
      final map = item as Map<String, dynamic>;
      
      final title = map['title'] as String? ?? '';
      final slug = map['slug'] as String? ?? map['id'] as String? ?? '';
      final description = map['description'] as String?;
      final imageUrl = map['image'] as String? ?? map['imageUrl'] as String?;
      
      // Filter out unwanted items
      if (title.isEmpty || 
          slug.isEmpty || 
          title.toLowerCase().contains('filtercontainer_inner') ||
          slug.toLowerCase().contains('filtercontainer_inner')) {
        return null;
      }
      
      // Build URLs
      final href = 'podcast/$slug';
      final absoluteUrl = '$_baseUrl/$href';
      
      return Podcast(
        title: title,
        href: href,
        absoluteUrl: absoluteUrl,
        description: description,
        imageUrl: imageUrl,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Fallback: Parses podcasts from HTML DOM
  static List<Podcast> _parsePodcastsFromHtml(String htmlContent) {
    final podcasts = <Podcast>[];
    
    try {
      final document = html_parser.parse(htmlContent);
      
      // Only look for links within HorizontalCard4_article elements
      final cardContainers = document.querySelectorAll('[class*="HorizontalCard4_article"]');
      
      // If no HorizontalCard4_article containers found, return empty list
      if (cardContainers.isEmpty) {
        return podcasts;
      }
      
      // Look for podcast links within HorizontalCard4_article containers
      final links = <html_dom.Element>[];
      for (final container in cardContainers) {
        final containerLinks = container.querySelectorAll('a[href*="/podcast/"]');
        links.addAll(containerLinks);
      }
      
      for (final link in links) {
        final href = link.attributes['href'];
        if (href == null || !href.startsWith('/podcast/')) continue;
        
        final absoluteUrl = href.startsWith('/') ? '$_baseUrl$href' : href;
        final relativeHref = href.startsWith('/') ? href.substring(1) : href;
        
        // Extract title
        final title = link.text.trim();
        if (title.isEmpty || title.toLowerCase().contains('filtercontainer_inner')) continue;
        
        // Try to find description and image in parent elements
        final parent = link.parent;
        String? description;
        String? imageUrl;
        
        if (parent != null) {
          final descElement = parent.querySelector('p, .description, [class*="description"]');
          description = descElement?.text.trim();
          
          final imgElement = parent.querySelector('img');
          imageUrl = imgElement?.attributes['src'] ?? imgElement?.attributes['data-src'];
        }
        
        // Remove .html extension if present
        String cleanUrl = absoluteUrl;
        if (cleanUrl.endsWith('.html')) {
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - 5);
        }
        
        podcasts.add(Podcast(
          title: title,
          href: relativeHref,
          absoluteUrl: cleanUrl,
          description: description,
          imageUrl: imageUrl,
        ));
      }
    } catch (e) {
      // If HTML parsing fails, return empty list
    }
    
    return podcasts;
  }
}

