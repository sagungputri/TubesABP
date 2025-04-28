import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'news_page.dart';
import 'news_detail_screen.dart';
import 'bookmark_service.dart';

class BookmarkScreen extends StatefulWidget {
  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<NewsArticle> _bookmarkedArticles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await BookmarkService.getBookmarks();
      if (mounted) {
        setState(() {
          _bookmarkedArticles = bookmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeBookmark(NewsArticle article) async {
    await BookmarkService.removeBookmark(article);
    _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Artikel Tersimpan'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _bookmarkedArticles.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tidak ada artikel tersimpan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Simpan artikel untuk dibaca nanti',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _bookmarkedArticles.length,
                itemBuilder: (context, index) {
                  final article = _bookmarkedArticles[index];
                  return Dismissible(
                    key: Key(article.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _removeBookmark(article);
                    },
                    child: _buildBookmarkItem(context, article),
                  );
                },
              ),
    );
  }

  Widget _buildBookmarkItem(BuildContext context, NewsArticle article) {
    // Implementasi sama seperti di news_page.dart
    // Salin metode _buildNewsItem dan sesuaikan
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          // ... implementasi sama seperti news_page.dart
        ),
      ),
    );
  }
}
