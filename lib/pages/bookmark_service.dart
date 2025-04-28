import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'news_page.dart'; // Assuming NewsArticle is defined here

class BookmarkService {
  static const String _bookmarksKey = 'news_bookmarks';

  // Save a bookmarked article
  static Future<void> addBookmark(NewsArticle article) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing bookmarks
    List<String> bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

    // Convert article to JSON string
    String articleJson = json.encode(article.toJson());

    // Check if article is not already bookmarked
    if (!bookmarks.contains(articleJson)) {
      bookmarks.add(articleJson);
      await prefs.setStringList(_bookmarksKey, bookmarks);
    }
  }

  // Remove a bookmarked article
  static Future<void> removeBookmark(NewsArticle article) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing bookmarks
    List<String> bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

    // Convert article to JSON string
    String articleJson = json.encode(article.toJson());

    // Remove the article
    bookmarks.removeWhere((item) => item == articleJson);

    await prefs.setStringList(_bookmarksKey, bookmarks);
  }

  // Check if an article is bookmarked
  static Future<bool> isBookmarked(NewsArticle article) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing bookmarks
    List<String> bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

    // Convert article to JSON string
    String articleJson = json.encode(article.toJson());

    return bookmarks.contains(articleJson);
  }

  // Get all bookmarked articles
  static Future<List<NewsArticle>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing bookmarks
    List<String> bookmarkStrings = prefs.getStringList(_bookmarksKey) ?? [];

    // Convert JSON strings back to NewsArticle objects
    List<NewsArticle> bookmarks =
        bookmarkStrings.map((jsonStr) {
          return NewsArticle.fromJson(json.decode(jsonStr));
        }).toList();

    return bookmarks;
  }
}

// Extend NewsArticle with toJson method for serialization
extension NewsArticleExtension on NewsArticle {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'category': category,
      'headline': headline,
      'content': content,
      'description': description,
      'author': author,
      'publishedAt': publishedAt,
      'url': url,
      'sourceName': sourceName,
      'sourceIcon': sourceIcon,
      'countries': countries,
      'categories': allCategories,
    };
  }
}
