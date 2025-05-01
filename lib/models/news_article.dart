class NewsArticle {
  final String title;
  final String href;
  final String absoluteUrl;
  final String? description;
  final String? imageUrl;
  final String? publicationDate;
  final String? category;

  const NewsArticle({
    required this.title,
    required this.href,
    required this.absoluteUrl,
    this.description,
    this.imageUrl,
    this.publicationDate,
    this.category,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    String? image = json['image'] as String?;
    // Unescape any HTML-escaped ampersands from scraped URLs
    if (image != null) {
      image = image.replaceAll('&amp;', '&');
    }
    return NewsArticle(
      title: json['title'] as String? ?? '',
      href: json['href'] as String? ?? '',
      absoluteUrl: json['absolute_url'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: image,
      publicationDate: json['publicationDate'] as String? ?? json['date'] as String?,
      category: json['category'] as String?,
    );
  }
}

