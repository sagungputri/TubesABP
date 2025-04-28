// Updated news_model.dart
import 'package:flutter/foundation.dart';

class NewsArticle {
  final String imageUrl;
  final String category;
  final String headline;
  final String content;
  final String author;
  final String publishedAt;
  bool isBookmarked;

  NewsArticle({
    required this.imageUrl,
    required this.category,
    required this.headline,
    this.content = 'No content available',
    this.author = 'Unknown',
    this.publishedAt = '',
    this.isBookmarked = false,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      imageUrl: json['urlToImage'] ?? '',
      category: json['source']['name'] ?? '',
      headline: json['title'] ?? '',
      content: json['content'] ?? json['description'] ?? 'No content available',
      author: json['author'] ?? 'Unknown',
      publishedAt: json['publishedAt'] ?? '',
      isBookmarked: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'category': category,
      'headline': headline,
      'content': content,
      'author': author,
      'publishedAt': publishedAt,
    };
  }
}

class BookmarkManager extends ChangeNotifier {
  List<NewsArticle> _bookmarkedArticles = [];

  List<NewsArticle> get bookmarkedArticles => _bookmarkedArticles;

  void toggleBookmark(NewsArticle article) {
    if (_bookmarkedArticles.contains(article)) {
      _bookmarkedArticles.remove(article);
      article.isBookmarked = false;
    } else {
      _bookmarkedArticles.add(article);
      article.isBookmarked = true;
    }
    notifyListeners();
  }

  void removeBookmark(NewsArticle article) {
    _bookmarkedArticles.remove(article);
    article.isBookmarked = false;
    notifyListeners();
  }
}
