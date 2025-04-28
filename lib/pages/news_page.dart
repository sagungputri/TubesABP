import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'news_detail_screen.dart';
import 'bookmark_service.dart';

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
    List<String> categoriesList =
        json['category'] != null ? List<String>.from(json['category']) : [];
    String primaryCategory =
        categoriesList.isNotEmpty
            ? categoriesList.first.isNotEmpty
                ? categoriesList.first.toUpperCase()
                : 'NEWS'
            : 'NEWS';

    List<String> countriesList =
        json['country'] != null ? List<String>.from(json['country']) : [];

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

// --- main() and MyApp remain the same ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Ensure this path is correct
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

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedChipIndex = 0;
  int _bottomNavIndex = 0;
  bool _isDigestVisible = true;
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

  String _dailyDigest = '';
  bool _isGeneratingDigest = false;
  String _digestError = '';
  GenerativeModel? _geminiModel;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    fetchNews();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);
  }

  void _initializeGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        _geminiModel = GenerativeModel(
          model: 'gemini-2.0-flash',

          // model: 'gemini-1.5-pro-latest',
          // model: 'gemini-pro',
          apiKey: apiKey,
        );
      } catch (e) {
        print("Error initializing Gemini Model: $e");
        if (mounted) {
          setState(() {
            _digestError = 'Error initializing AI Model. Digest unavailable.';
          });
        }
        _geminiModel = null;
      }
    } else {
      print(
        "Warning: GEMINI_API_KEY not found in .env file. AI Digest feature disabled.",
      );
      if (mounted) {
        setState(() {
          _digestError = 'Gemini API Key not found. Digest unavailable.';
        });
      }
      _geminiModel = null;
    }
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _hasMoreData && _nextPageToken != null) {
        if (mounted) {
          _loadMoreNews();
        }
      }
    }
  }

  Future<void> fetchNews({bool isRefresh = true}) async {
    if (!mounted) return;

    final String newsApiKey = dotenv.env['NEWSDATA_API_KEY'] ?? '';
    if (newsApiKey.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Newsdata API key not found. Please check your .env file.';
          _dailyDigest = ''; // Clear digest on API key error
          _digestError = '';
        });
      }
      return;
    }

    String apiCategory =
        _selectedChipIndex > 0
            ? _chipLabels[_selectedChipIndex].toLowerCase()
            : ''; // Fetch general news if 'All' is selected

    final queryParams = {
      'apikey': newsApiKey,
      'language': 'en',
      'image': '1',
      'size': '10',
      // Prioritize headlines for digest
      // 'country': 'jp,us,gb', // Example: Focus on specific countries if needed
    };

    if (apiCategory.isNotEmpty) {
      queryParams['category'] = apiCategory;
    }

    if (!isRefresh && _nextPageToken != null) {
      queryParams['page'] = _nextPageToken!;
    }

    final Uri uri = Uri.https('newsdata.io', '/api/1/news', queryParams);
    print("Fetching News URL: $uri");

    try {
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _isLoading = true;
            _newsArticles.clear();
            _nextPageToken = null;
            _hasMoreData = true;
            // buat reset digest state on refresh
            _dailyDigest = '';
            _digestError = '';
            _isGeneratingDigest = false;
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
        // print('News articles fetched successfully: ${data['results']}');
        if (data['status'] == 'success') {
          final List results = data['results'] ?? [];
          final String? nextPage = data['nextPage'];

          final newArticles =
              results
                  .map((articleJson) => NewsArticle.fromJson(articleJson))
                  .toList();

          if (mounted) {
            setState(() {
              if (isRefresh) {
                _newsArticles = newArticles;
              } else {
                _newsArticles.addAll(newArticles);
              }
              _nextPageToken = nextPage;
              _hasMoreData = nextPage != null && newArticles.isNotEmpty;
              _isLoading = false;
              _isLoadingMore = false;
            });

            if (isRefresh && _newsArticles.isNotEmpty && _geminiModel != null) {
              _generateDailyDigest(
                _newsArticles.map((a) => a.headline).toList(),
              );
            } else if (isRefresh && _geminiModel == null) {
              setState(() {
                _digestError = 'Gemini API Key not found. Digest unavailable.';
                _isGeneratingDigest = false;
                _dailyDigest = '';
              });
            }
          }
        } else {
          throw Exception(
            'News API returned error: ${data['results']?['message'] ?? data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load news: HTTP ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e, stackTrace) {
      print("Error fetching news: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = 'Failed to load news. Check connection or API key.';
          _dailyDigest = '';
          _digestError = '';
          _isGeneratingDigest = false;
        });
      }
    }
  }

  Future<void> _generateDailyDigest(List<String> headlines) async {
    if (_geminiModel == null || headlines.isEmpty || !mounted) {
      if (_geminiModel == null && mounted) {
        setState(() {
          _digestError = 'Gemini API Key not found. Digest unavailable.';
          _isGeneratingDigest = false;
          _dailyDigest = '';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isGeneratingDigest = true;
      _digestError = '';
      _dailyDigest = '';
    });

    final headlinesToSend = headlines.take(15).toList();
    final prompt = '''
      You are a helpful news summarizer. I will provide you with a list of recent news headlines.
      Your task is to generate a short, engaging 'daily digest' or 'newsletter intro' (2-4 sentences) summarizing the key events or trends based *only* on these headlines.
      Do not invent information not present in the headlines. Make it sound like a concise digital newspaper summary.

      Headlines:
      - ${headlinesToSend.join("\n- ")}

      Generate the summary:
    ''';

    print("--- Sending Prompt to Gemini ---");
    // print(prompt);
    print("Headlines Count: ${headlinesToSend.length}");
    print("--- End Prompt ---");

    try {
      final response = await _geminiModel!.generateContent([
        Content.text(prompt),
      ]);

      if (!mounted) return;

      if (response.text != null && response.text!.isNotEmpty) {
        print("Gemini Response: ${response.text}");
        setState(() {
          _dailyDigest = response.text!;
          _isGeneratingDigest = false;
          _digestError = '';
        });
      } else {
        throw Exception("Gemini returned an empty response.");
      }
    } catch (e, stackTrace) {
      print("Error generating digest with Gemini: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          _digestError = 'Could not generate AI digest. ${e.toString()}';
          _dailyDigest = '';
          _isGeneratingDigest = false;
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
      _dailyDigest = '';
      _digestError = '';
      _isGeneratingDigest = false;
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
            _buildDailyDigestWidget(),
            _buildTitle(),
            if (_errorMessage.isNotEmpty &&
                !_isLoading &&
                _newsArticles.isEmpty)
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
              child:
                  _isLoading
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

  Widget _buildDigestScrollableContent() {
    Widget content;

    if (_isGeneratingDigest) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(width: 10),
          Text(
            "Generating digest...",
            style: TextStyle(
              color: Colors.deepPurple[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else if (_digestError.isNotEmpty) {
      content = Text(
        _digestError,
        style: TextStyle(color: Colors.red[700], fontSize: 14),
        textAlign: TextAlign.center,
      );
    } else if (_dailyDigest.isNotEmpty) {
      content = Text(
        _dailyDigest,
        style: TextStyle(fontSize: 14.5, color: Colors.black87, height: 1.4),
      );
    } else if (!_isLoading && _newsArticles.isEmpty && _errorMessage.isEmpty) {
      content = Text(
        "Not enough headlines available to generate a digest for this category.",
        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      );
    } else if (_geminiModel == null) {
      content = Text(
        'Gemini API Key not configured. Digest unavailable.',
        style: TextStyle(color: Colors.orange[800]),
        textAlign: TextAlign.center,
      );
    } else {
      content = Text(
        "Fetching today's highlights...",
        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: content,
      ),
    );
  }

  Widget _buildDailyDigestWidget() {
    if (_geminiModel == null && _digestError.contains('Key not found')) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Text(
          _digestError,
          style: TextStyle(color: Colors.orange[800], fontSize: 13),
        ),
      );
    }
    if (_isLoading && _newsArticles.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "✨ AI Daily Digest",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[700],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isDigestVisible ? Icons.expand_less : Icons.expand_more,
                  color: Colors.deepPurple[400],
                ),
                tooltip: _isDigestVisible ? 'Hide Digest' : 'Show Digest',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                splashRadius: 20,
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _isDigestVisible = !_isDigestVisible;
                    });
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 8),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:
                _isDigestVisible
                    ? Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxHeight: 150.0),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.2),
                        ),
                      ),
                      child: _buildDigestScrollableContent(),
                    )
                    : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDigestContent() {
    if (_isGeneratingDigest) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(width: 10),
          Text(
            "Generating digest...",
            style: TextStyle(
              color: Colors.deepPurple[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else if (_digestError.isNotEmpty) {
      return Text(
        _digestError,
        style: TextStyle(color: Colors.red[700], fontSize: 14),
      );
    } else if (_dailyDigest.isNotEmpty) {
      return Text(
        _dailyDigest,
        style: TextStyle(fontSize: 14.5, color: Colors.black87, height: 1.4),
      );
    } else if (!_isLoading && _newsArticles.isEmpty && _errorMessage.isEmpty) {
      return Text(
        "Not enough headlines available to generate a digest for this category.",
        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      );
    } else if (_geminiModel == null) {
      return Text(
        'Gemini API Key not configured. Digest unavailable.',
        style: TextStyle(color: Colors.orange[800]),
      );
    } else {
      return Text(
        "Fetching today's highlights...",
        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
      );
    }
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
            suffixIcon:
                _searchQuery.isNotEmpty
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
            // This updates the query state variable, no need for setState here
            // if the listener _onSearchChanged is correctly implemented
            // _onSearchChanged(); // Call listener method
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
          children:
              List<Widget>.generate(_chipLabels.length, (index) {
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
                        color:
                            isSelected ? Colors.blue[700]! : Colors.grey[300]!,
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
      padding: const EdgeInsets.only(left: 16.0, top: 10.0, bottom: 10.0),
      child: Text(
        _selectedChipIndex == 0
            ? 'Top Headlines'
            : '${_chipLabels[_selectedChipIndex]} News',
        style: TextStyle(
          fontSize: 26,
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
      filteredData =
          _newsArticles
              .where(
                (article) =>
                    article.headline.toLowerCase().contains(query) ||
                    (article.description.isNotEmpty &&
                        article.description.toLowerCase().contains(query)) ||
                    article.sourceName.toLowerCase().contains(query) ||
                    (article.content.isNotEmpty &&
                        article.content.toLowerCase().contains(query)),
              )
              .toList();
    }

    if (!_isLoading && _newsArticles.isEmpty && _errorMessage.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, size: 60, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No articles found for "${_chipLabels[_selectedChipIndex]}" category.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Handle search results empty
    if (!_isLoading && filteredData.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No results found for "$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
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
      itemCount: filteredData.length + 1,
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
          final article = filteredData[index];
          if (article.id.isEmpty || article.headline.isEmpty) {
            return SizedBox.shrink();
          }
          return _buildNewsItem(context, article);
        }

        return SizedBox.shrink();
      },
    );
  }

  Widget _buildNewsItem(BuildContext context, NewsArticle article) {
    // if (article.id.isEmpty || article.headline.isEmpty) {
    //   return SizedBox.shrink();
    // }
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
                child:
                    article.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: article.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
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
                            Icons.article_outlined,
                            color: Colors.grey[500],
                            size: 32,
                          ),
                        ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              errorWidget:
                                  (context, url, error) => SizedBox.shrink(),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookmarkScreen()),
              );
            } else if (index == 0) {
              // Optional: Scroll to top when back to Home tab
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            }
          });
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
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

  void _removeBookmark(NewsArticle article) async {
    await BookmarkService.removeBookmark(article);
    _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked Articles'),
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
                      'No bookmarked articles',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Save articles to read later',
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
                child:
                    article.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: article.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
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
                            Icons.article_outlined,
                            color: Colors.grey[500],
                            size: 32,
                          ),
                        ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              errorWidget:
                                  (context, url, error) => SizedBox.shrink(),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
