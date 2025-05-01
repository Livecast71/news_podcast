import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../utils/news_scraper.dart';
import 'news_detail_page.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late final Future<List<NewsArticle>> _newsFuture = _loadNews();

  Future<List<NewsArticle>> _loadNews() async {
    try {
      debugPrint('Scraping news...');
      final scraped = await NewsScraper.scrapeNews();
      if (scraped.isNotEmpty) {
        debugPrint('Successfully scraped ${scraped.length} news articles');
        return scraped;
      }
    } catch (e) {
      debugPrint('Scraping failed: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<NewsArticle>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadNews();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final items = (snapshot.data ?? const <NewsArticle>[])
              .where((a) => !a.title.toLowerCase().contains('filtercontainer_inner'))
              .toList();
          if (items.isEmpty) {
            return const Center(child: Text('No news articles found'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final article = items[index];
              return Card(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NewsDetailPage(article: article),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              article.imageUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.image_not_supported, color: Colors.amber),
                                  ),
                            ),
                          ),
                        if (article.imageUrl != null) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (article.category != null) ...[
                                Text(
                                  article.category!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber[300],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                article.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (article.description != null && article.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  article.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              if (article.publicationDate != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  article.publicationDate!,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

