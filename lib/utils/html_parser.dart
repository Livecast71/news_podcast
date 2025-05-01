import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class PodcastHtmlParser {
  static Map<String, dynamic>? parseJsonData(String htmlContent) {
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

  static Map<String, dynamic>? extractPodcastData(String htmlContent) {
    final jsonData = parseJsonData(htmlContent);
    if (jsonData == null) return null;
    
    final props = jsonData['props'] as Map<String, dynamic>?;
    if (props == null) return null;
    
    final pageProps = props['pageProps'] as Map<String, dynamic>?;
    if (pageProps == null) return null;
    
    return pageProps;
  }
}

