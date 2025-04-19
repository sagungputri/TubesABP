import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewsArticle {
  final String imageUrl;
  final String category;
  final String headline;

  NewsArticle({
    required this.imageUrl,
    required this.category,
    required this.headline,
  });
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      imageUrl: json['urlToImage'] ?? '',
      category: json['source']['name'] ?? '',
      headline: json['title'] ?? '',
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App UI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Sans-serif',
      ),
      home: NewsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int _selectedChipIndex = 2;
  int _bottomNavIndex = 0;

  final List<String> _chipLabels = [
    'Urutkan',
    'Technology',
    'Business',
    'Travel',
    'Politics',
  ];
  List<NewsArticle> _newsArticles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    final String apiKey = 'a0eda362f6c640ec94892514e456d322';
    final String url =
        'https://newsapi.org/v2/top-headlines?country=us&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List articles = data['articles'];

        setState(() {
          _newsArticles =
              articles.map((article) => NewsArticle.fromJson(article)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar bisa dikosongkan klo gk perlu title di atas
      // appBar: AppBar(
      //   backgroundColor: Colors.grey[50],
      //   elevation: 0,
      // ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBarPlaceholder(),
            _buildSearchBar(),
            _buildFilterChips(),
            _buildTitle(),
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _buildNewsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildStatusBarPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 18),
              SizedBox(width: 4),
              Icon(Icons.wifi, size: 18),
              SizedBox(width: 4),
              Icon(Icons.battery_full, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search News',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 8.0),
              child: Icon(Icons.search, color: Colors.grey[800]),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15.0),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              List<Widget>.generate(_chipLabels.length, (index) {
                bool isSelected = _selectedChipIndex == index;
                bool isFirstChip = index == 0;

                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFirstChip)
                          Icon(
                            Icons.swap_vert,
                            size: 18,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        if (isFirstChip) SizedBox(width: 4),
                        Text(_chipLabels[index]),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedChipIndex = index;
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.grey[700],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(color: Colors.grey[300]!, width: 1.0),
                    ),
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 20.0, bottom: 10.0),
      child: Text(
        'News',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    List<NewsArticle> filteredData = _newsArticles;

    if (_selectedChipIndex != 0 && _selectedChipIndex < _chipLabels.length) {
      String selectedCategory = _chipLabels[_selectedChipIndex];
      filteredData =
          _newsArticles
              .where(
                (a) =>
                    a.category.toLowerCase() == selectedCategory.toLowerCase(),
              )
              .toList();
    }

    return ListView.builder(
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        return _buildNewsItem(filteredData[index]);
      },
    );
  }

  Widget _buildNewsItem(NewsArticle article) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                article.imageUrl,
                width: 100, // lebar gambar thumbnail
                height: 100, // tnggi gambar thumbnail
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                      ),
                    ), //  placeholder jika  gagal
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 5.0),
                  Text(
                    article.headline,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 4, // max baris
                    overflow: TextOverflow.ellipsis, // "..."kalau trllu panjang
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
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
    );
  }
}
