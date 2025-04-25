// Model News
class NewsArticle {
  final String imageUrl;
  final String category;
  final String headline;
  final String content;
  final String author;
  final String publishedAt;

  NewsArticle({
    required this.imageUrl,
    required this.category,
    required this.headline,
    this.content = 'No content available',
    this.author = 'Unknown',
    this.publishedAt = '',
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      imageUrl: json['urlToImage'] ?? '',
      category: json['source']['name'] ?? '',
      headline: json['title'] ?? '',
      content: json['content'] ?? json['description'] ?? 'No content available',
      author: json['author'] ?? 'Unknown',
      publishedAt: json['publishedAt'] ?? '',
    );
  }
}