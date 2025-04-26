import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'news_detail_screen.dart'; 

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
  final List<String> allCategories; 

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
    required this.allCategories,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {    
    List<String> categoriesList = json['category'] != null
        ? List<String>.from(json['category'])
        : [];
    String primaryCategory = categoriesList.isNotEmpty
        ? categoriesList.first.isNotEmpty ? categoriesList.first.toUpperCase() : 'NEWS'
        : 'NEWS'; 
    
    List<String> countriesList = json['country'] != null
        ? List<String>.from(json['country'])
        : [];
    
    String authorText = 'Unknown';
    if (json['creator'] != null) {
      if (json['creator'] is List) {
        if (json['creator'].isNotEmpty && json['creator'][0] != null) {
          authorText = json['creator'][0].toString();
        }
      } else {
        authorText = json['creator'].toString();
      }
    }

    return NewsArticle(      
      id: json['article_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      category: primaryCategory,
      headline: json['title']?.toString() ?? 'No Title',
      content: json['content']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      author: authorText,
      publishedAt: json['pubDate']?.toString() ?? '',
      url: json['link']?.toString() ?? '',
      sourceName: json['source_id']?.toString() ?? 'Unknown Source', 
      sourceIcon: json['source_icon']?.toString() ?? '',
      countries: countriesList,
      allCategories: categoriesList,
    );
  }
}

Future<void> main() async {  
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "/Users/azmi/Productive/Webdev/TubesABP/.env");
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
  int _selectedChipIndex = 0;
  int _bottomNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<String> _chipLabels = [
    'All',
    'Technology',
    'Business',
    'Health',
    'Science',
    'Sports',
    'Entertainment',
    'World',
  ];
  List<NewsArticle> _newsArticles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String _errorMessage = '';
  String? _nextPageToken;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchNews();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _hasMoreData && _nextPageToken != null) {
        if (mounted) {
          _loadMoreNews();
        }
      }
    }
  }

  Future<void> fetchNews({bool isRefresh = true}) async {
    if (!mounted) return;

    final String apiKey = dotenv.env['NEWSDATA_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'API key (NEWSDATA_API_KEY) not found. Please check your .env file.';
        });
      }
      return;
    }

    String apiCategory = _selectedChipIndex > 0
        ? _chipLabels[_selectedChipIndex].toLowerCase()
        : '';

    final queryParams = {
      'apikey': apiKey,
      'language': 'en',
      'image': '1',
      'size': '10',
    };

    if (apiCategory.isNotEmpty) {
      queryParams['category'] = apiCategory;
    }

    if (!isRefresh && _nextPageToken != null) {
      queryParams['page'] = _nextPageToken!;
    }

    final Uri uri = Uri.https('newsdata.io', '/api/1/news', queryParams);

    try {
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _isLoading = true;
            _newsArticles.clear();
            _nextPageToken = null;
            _hasMoreData = true;
          } else {
            _isLoadingMore = true;
          }
          _errorMessage = '';
        });
      }

      final response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('News articles fetched successfully: ${data['results']}');
        if (data['status'] == 'success') {
          final List results = data['results'] ?? [];
          final String? nextPage = data['nextPage'];

          final newArticles = results
              .map((articleJson) => NewsArticle.fromJson(articleJson))
              .toList();

          setState(() {
            _newsArticles.addAll(newArticles);
            _nextPageToken = nextPage;
            _hasMoreData = nextPage != null && newArticles.isNotEmpty;
            _isLoading = false;
            _isLoadingMore = false;
          });
        } else {
          throw Exception('API returned error: ${data['results']?['message'] ?? data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load news: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = 'Failed to load news. Check connection or API key.';
        });
      }
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoadingMore || !_hasMoreData || _nextPageToken == null) return;
    await fetchNews(isRefresh: false);
  }

  void _onCategoryChanged(int index) {
    if (_selectedChipIndex == index) return;

    setState(() {
      _selectedChipIndex = index;
      _isLoading = true;
      _newsArticles = [];
      _nextPageToken = null;
      _hasMoreData = true;
      _errorMessage = '';
      _scrollController.jumpTo(0);
    });
    fetchNews(isRefresh: true);
  }

  Future<void> _refreshNews() async {
    await fetchNews(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            _buildTitle(),
            if (_errorMessage.isNotEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _refreshNews,
                      child: _buildNewsList(),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search News (headlines, description...)',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 8.0),
              child: Icon(Icons.search, color: Colors.grey[800]),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15.0),
          ),
          onChanged: (value) {
            if (mounted) {
              setState(() {
                _searchQuery = value;
              });
            }
          },
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
          children: List<Widget>.generate(_chipLabels.length, (index) {
            bool isSelected = _selectedChipIndex == index;

            return Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(_chipLabels[index]),
                selected: isSelected,
                onSelected: (bool selected) {
                  if (selected) {
                    _onCategoryChanged(index);
                  }
                },
                backgroundColor: Colors.white,
                selectedColor: Colors.blue[700],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                    width: 1.0,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
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
        _selectedChipIndex == 0 ? 'Top Headlines' : '${_chipLabels[_selectedChipIndex]} News',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    List<NewsArticle> filteredData = _newsArticles;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredData = _newsArticles.where((article) =>
          article.headline.toLowerCase().contains(query) ||
          article.description.toLowerCase().contains(query) ||
          article.sourceName.toLowerCase().contains(query) ||
          article.content.toLowerCase().contains(query)).toList();
    }

    if (!_isLoading && filteredData.isEmpty && _errorMessage.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.article_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found for "$_searchQuery"'
                  : 'No articles found for this category.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Try searching for something else.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredData.length + (_isLoadingMore || !_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredData.length) {
          if (_isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (!_hasMoreData && _newsArticles.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'You\'ve reached the end!',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            );
          } else {
            return SizedBox.shrink();
          }
        }

        if (index < filteredData.length) {
          return _buildNewsItem(context, filteredData[index]);
        }

        return SizedBox.shrink();
      },
    );
  }

  Widget _buildNewsItem(BuildContext context, NewsArticle article) {
    if (article.id.isEmpty || article.headline.isEmpty) {
      return SizedBox.shrink();
    }
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
                child: article.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: article.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[500],
                            size: 30,
                          ),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(
                          Icons.article,
                          color: Colors.grey[500],
                          size: 32,
                        ),
                      ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (article.sourceIcon.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: CachedNetworkImage(
                              imageUrl: article.sourceIcon,
                              width: 14,
                              height: 14,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => SizedBox.shrink(),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            article.sourceName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        if (article.category != 'NEWS')
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              article.category,
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6.0),
                    Text(
                      article.headline,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.0),
                    if (article.description.isNotEmpty)
                      Text(
                        article.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (index) {
        if (mounted) {
          setState(() {
            _bottomNavIndex = index;
            if (index == 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bookmark Screen Tapped (Not Implemented)')),
              );
            }
          });
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border),
          activeIcon: Icon(Icons.bookmark),
          label: 'Saved',
        ),
      ],
      selectedItemColor: Colors.blue[800],
      unselectedItemColor: Colors.grey[600],
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 8.0,
      showUnselectedLabels: true,
    );
  }
}
