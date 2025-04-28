import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'news_page.dart'; // Assuming NewsArticle is defined here

class BookmarkService {
  static const String _bookmarksKey = 'news_bookmarks';

  // Save a bookmarked article
  static Future<void> addBookmark(NewsArticle article) async {
    final prefs = await SharedPreferences.getInstance();

    // Ambil daftar bookmark yang sudah ada
    List<String> bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

    // Konversi artikel ke JSON string
    String articleJson = json.encode({
      'id': article.id,
      'imageUrl': article.imageUrl,
      'category': article.category,
      'headline': article.headline,
      'content': article.content,
      'description': article.description,
      'author': article.author,
      'publishedAt': article.publishedAt,
      'url': article.url,
      'sourceName': article.sourceName,
      'sourceIcon': article.sourceIcon,
      'countries': article.countries,
      'allCategories': article.allCategories,
    });

    // Cek apakah artikel sudah ada di bookmark
    bool isAlreadyBookmarked = bookmarks.any((bookmark) {
      Map<String, dynamic> existingArticle = json.decode(bookmark);
      return existingArticle['id'] == article.id;
    });

    if (!isAlreadyBookmarked) {
      bookmarks.add(articleJson);
      await prefs.setStringList(_bookmarksKey, bookmarks);
      print('Artikel berhasil dibookmark: ${article.headline}');
    }
  }

  // Hapus bookmark
  static Future<void> removeBookmark(NewsArticle article) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

    // Hapus artikel berdasarkan ID
    bookmarks.removeWhere((bookmark) {
      Map<String, dynamic> existingArticle = json.decode(bookmark);
      return existingArticle['id'] == article.id;
    });

    await prefs.setStringList(_bookmarksKey, bookmarks);
    print('Artikel dihapus dari bookmark: ${article.headline}');
  }

  // Periksa apakah artikel sudah di-bookmark
  static Future<bool> isBookmarked(NewsArticle article) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

    return bookmarks.any((bookmark) {
      Map<String, dynamic> existingArticle = json.decode(bookmark);
      return existingArticle['id'] == article.id;
    });
  }

  // Dapatkan semua bookmark
  static Future<List<NewsArticle>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> bookmarkStrings = prefs.getStringList(_bookmarksKey) ?? [];

    List<NewsArticle> bookmarks =
        bookmarkStrings.map((bookmarkJson) {
          Map<String, dynamic> articleMap = json.decode(bookmarkJson);
          return NewsArticle.fromJson(articleMap);
        }).toList();

    print('Jumlah artikel yang di-bookmark: ${bookmarks.length}');
    return bookmarks;
  }
}
