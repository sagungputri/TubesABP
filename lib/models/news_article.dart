class NewsArticle {
  final String articleId;
  final String title;
  final String? link;
  final String? sourceId;
  final String? sourceUrl;
  final String? imageUrl;
  final String? description;
  final String? pubDate;
  final List<String> category;
  final String language;

  NewsArticle({
    required this.articleId,
    required this.title,
    this.link,
    this.sourceId,
    this.sourceUrl,
    this.imageUrl,
    this.description,
    this.pubDate,
    required this.category,
    required this.language,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    // Safely handle potential nulls and type conversions
    return NewsArticle(
      articleId: json['article_id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? 'No Title Provided',
      link: json['link'], 
      sourceId: json['source_id'], 
      sourceUrl: json['source_url'], 
      imageUrl: json['image_url'], 
      description: json['description'], 
      pubDate: json['pubDate'], 
      category: (json['category'] as List<dynamic>?)
              ?.map((e) => e.toString())
              ?.toList() ??
          ['uncategorized'],
      language: json['language'] ?? 'unknown',
    );
  }
}

// Model untuk response API secara keseluruhan (opsional tapi bagus)
class NewsApiResponse {
    final String status;
    final int totalResults;
    final List<NewsArticle> articles;
    final String? nextPage;
    final String? errorMessage; 

    NewsApiResponse({
        required this.status,
        required this.totalResults,
        required this.articles,
        this.nextPage,
        this.errorMessage,
    });

    factory NewsApiResponse.fromJson(Map<String, dynamic> json) {
        List<NewsArticle> articlesList = [];
        if (json['status'] == 'success' && json['results'] != null && json['results'] is List) {
            articlesList = (json['results'] as List)
                .map((item) => NewsArticle.fromJson(item))
                .toList();
        }

        String? errorMsg;
        // Jika status error, coba ambil pesan error (struktur bisa bervariasi)
        if (json['status'] == 'error' && json['results'] != null && json['results'] is Map) {
             errorMsg = json['results']['message'] ?? 'Unknown error occurred';
        } else if (json['status'] == 'error') {
             errorMsg = json['message'] ?? 'Unknown error occurred'; // Coba fallback
        }


        return NewsApiResponse(
            status: json['status'] ?? 'unknown',
            totalResults: (json['totalResults'] is int) ? json['totalResults'] : 0,
            articles: articlesList,
            nextPage: json['nextPage'],
            errorMessage: errorMsg, 
        );
    }
}