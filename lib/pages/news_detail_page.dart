import 'package:flutter/material.dart';
import '../models/news_model.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  _NewsDetailScreenState createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool isBookmarked = false;

  int _bottomNavIndex = 0; // Indeks untuk BottomNavigationBar

  void _onItemTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      // Navigasi berdasarkan tab yang dipilih
      if (_bottomNavIndex == 0) {
        // Aksi untuk Home
        Navigator.pushReplacementNamed(context, '/home');
      } else if (_bottomNavIndex == 1) {
        // Aksi untuk Bookmark
        Navigator.pushReplacementNamed(context, '/bookmarks');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Detail'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.share),
          //   onPressed: () {
          //     Share.share('Check out this news: ${article.headline}');
          //   },
          // ),
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              setState(() {
                isBookmarked = !isBookmarked;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBookmarked
                        ? 'News saved to bookmarks'
                        : 'Bookmark removed',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            Container(
              width: double.infinity,
              height: 250,
              child: Image.network(
                widget.article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                        size: 50,
                      ),
                    ),
              ),
            ),

            // Category badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.article.category,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // Headline
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                widget.article.headline,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),

            // Author and date
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'By ${widget.article.author}',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(widget.article.publishedAt),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Divider
            Padding(padding: const EdgeInsets.all(16.0), child: Divider()),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.article.content,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          print("Summarize button clicked");
        },
        label: Text('Summarize'),
        icon: Icon(Icons.summarize),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (index) {
        setState(() {
          _bottomNavIndex = index;
          // Tambahin navigasi ke halaman lain di sini klo butuh nanti
          // if (index == 0) { // Home
          // } else if (index == 1) { // Bookmark
          // }
        });
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border),
          activeIcon: Icon(Icons.bookmark),
          label: 'Bookmark',
        ),
      ],
      selectedItemColor: Colors.blue[800],
      unselectedItemColor: Colors.grey[600],
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 5.0,
    )
      
    );
  }

  // Buat format date
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
