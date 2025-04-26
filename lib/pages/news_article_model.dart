class NewsArticle {
  final String id;
  final String imageUrl;
  final String category;
  final String headline;
  final String content;
  final String description;
  final String author;
  final String publishedAt;
  final String url;
  final String sourceName;
  final String sourceIcon;
  final List<String> countries;
  final List<String> categories;

  NewsArticle({
    required this.id,
    required this.imageUrl,
    required this.category,
    required this.headline,
    this.content = '',
    this.description = '',
    this.author = '',
    required this.publishedAt,
    required this.url,
    required this.sourceName,
    this.sourceIcon = '',
    required this.countries,
    required this.categories,
  });
  
  factory NewsArticle.fromJson(Map<String, dynamic> json) {    
    List<String> categoriesList = [];
    if (json['category'] != null) {
      categoriesList = List<String>.from(json['category']);
    }
        
    List<String> countriesList = [];
    if (json['country'] != null) {
      countriesList = List<String>.from(json['country']);
    }
        
    String primaryCategory = categoriesList.isNotEmpty 
        ? categoriesList.first.toUpperCase() 
        : 'NEWS';
    
    return NewsArticle(
      id: json['article_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: primaryCategory,
      headline: json['title'] ?? '',
      content: json['content'] ?? '',
      description: json['description'] ?? '',
      author: json['creator'] != null ? json['creator'].toString() : 'Unknown',
      publishedAt: json['pubDate'] ?? '',
      url: json['link'] ?? '',
      sourceName: json['source_name'] ?? '',
      sourceIcon: json['source_icon'] ?? '',
      countries: countriesList,
      categories: categoriesList,
    );
  }
}