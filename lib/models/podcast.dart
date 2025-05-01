class Podcast {
  final String title;
  final String href;
  final String absoluteUrl;
  final String? description;
  final String? imageUrl;

  const Podcast({
    required this.title,
    required this.href,
    required this.absoluteUrl,
    this.description,
    this.imageUrl,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    String? image = json['image'] as String?;
    // Unescape any HTML-escaped ampersands from scraped URLs
    if (image != null) {
      image = image.replaceAll('&amp;', '&');
    }
    return Podcast(
      title: json['title'] as String? ?? '',
      href: json['href'] as String? ?? '',
      absoluteUrl: json['absolute_url'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: image,
    );
  }
}
