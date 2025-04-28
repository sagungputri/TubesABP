import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'news_page.dart';
import 'bookmark_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  _NewsDetailScreenState createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _isLoadingRelated = true;
  bool _isBookmarked = false;
  List<NewsArticle> _relatedArticles = [];
  String? _relatedNextPageToken;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRelatedArticles();
    _checkIfBookmarked();
  }

  Future<void> _checkIfBookmarked() async {
    try {
      final bookmarked = await BookmarkService.isBookmarked(widget.article);
      if (mounted) {
        setState(() {
          _isBookmarked = bookmarked;
        });
      }
    } catch (e) {
      print('Error checking bookmark status: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      if (_isBookmarked) {
        await BookmarkService.removeBookmark(widget.article);
      } else {
        await BookmarkService.addBookmark(widget.article);
      }

      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });

        // Show a snackbar to provide feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked ? 'Article bookmarked' : 'Bookmark removed',
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update bookmark'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _fetchRelatedArticles() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRelated = true;
      _errorMessage = '';
      _relatedArticles.clear(); // Clear previous related articles
      _relatedNextPageToken = null; // Reset token
    });

    try {
      // Use the SAME API Key name as in news_page.dart
      final String? apiKey = dotenv.env['NEWSDATA_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key (NEWSDATA_API_KEY) not found');
      }

      final String query = widget.article.category.toLowerCase();

      // Construct query parameters
      final queryParams = {
        'apikey': apiKey,
        'q': query, // Use category as query term
        'language': 'en',
        'size': '5', // Fetch a few related articles
        'image': '1', // Request images for related articles too
      };

      final relatedUrl = Uri.https('newsdata.io', '/api/1/news', queryParams);
      print("Fetching Related URL: $relatedUrl");

      final response = await http.get(relatedUrl);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success' && data['results'] != null) {
          final List<dynamic> results = data['results'];
          final String? nextPage = data['nextPage'];

          // Filter out the current article and map to NewsArticle objects
          final newRelatedArticles =
              results
                  .map<NewsArticle>((json) => NewsArticle.fromJson(json))
                  .where(
                    (relatedArticle) => relatedArticle.id != widget.article.id,
                  ) // Filter out the current article
                  .toList();

          setState(() {
            _relatedArticles = newRelatedArticles;
            _relatedNextPageToken =
                nextPage; // Store the token for potential 'load more'
            _isLoadingRelated = false;
          });
        } else {
          print(
            "Related API Error: ${data['results']?['message'] ?? data['message'] ?? 'Unknown API error'}",
          );
          throw Exception('API returned error for related articles');
        }
      } else {
        print(
          "Related HTTP Error: ${response.statusCode}, Body: ${response.body}",
        );
        throw Exception(
          'Failed to load related articles: HTTP ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print('Error fetching related articles: $e');
      print("Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
          _errorMessage = 'Could not load related articles.';
        });
      }
    }
  }

  Future<void> _fetchMoreRelatedArticles() async {
    if (_relatedNextPageToken == null || _isLoadingRelated) return;
    if (!mounted) return;

    setState(() {
      _isLoadingRelated = true;
    });

    try {
      final String? apiKey = dotenv.env['NEWSDATA_API_KEY'];
      if (apiKey == null || apiKey.isEmpty)
        throw Exception('API key not found');

      final String query = widget.article.category.toLowerCase();
      final queryParams = {
        'apikey': apiKey,
        'q': query,
        'language': 'en',
        'size': '5',
        'image': '1',
        'page': _relatedNextPageToken!,
      };

      final relatedUrl = Uri.https('newsdata.io', '/api/1/news', queryParams);
      print("Fetching More Related URL: $relatedUrl");

      final response = await http.get(relatedUrl);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['results'] != null) {
          final List<dynamic> results = data['results'];
          final String? nextPage = data['nextPage'];
          final newRelatedArticles =
              results
                  .map<NewsArticle>((json) => NewsArticle.fromJson(json))
                  .where(
                    (relatedArticle) => relatedArticle.id != widget.article.id,
                  )
                  .toList();

          setState(() {
            _relatedArticles.addAll(newRelatedArticles);
            _relatedNextPageToken = nextPage;
            _isLoadingRelated = false;
          });
        } else {
          throw Exception('API returned error for more related articles');
        }
      } else {
        throw Exception(
          'Failed to load more related articles: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching more related articles: $e');
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load more related articles.')),
          );
        });
      }
    }
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No URL available for this article')),
      );
      return;
    }
    final Uri uri = Uri.parse(url);
    try {
      bool launched = await canLaunchUrl(uri);
      if (launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $url');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open the link.')));
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening the link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: <Widget>[
          _buildSliverAppBar(context),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(),
              _buildContent(),
              if (widget.article.url.isNotEmpty) _buildSourceInfo(),
              _buildTags(),
              _buildRelatedNews(),
              SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 1.0, // Subtle elevation
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Colors.black87,
        ), // Use iOS style back arrow
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color:
                _isBookmarked
                    ? Colors.blue[700]
                    : Colors.black87, // Highlight if bookmarked
          ),
          tooltip: _isBookmarked ? 'Remove Bookmark' : 'Bookmark Article',
          onPressed: _toggleBookmark,
        ),
        IconButton(
          icon: Icon(Icons.share_outlined, color: Colors.black87),
          tooltip: 'Share Article',
          onPressed: () {
            // TODO: Implement share functionality (e.g., using share_plus package)
            if (widget.article.url.isNotEmpty) {
              print('Sharing URL: ${widget.article.url}');
              // Example: Share.share('Check out this article: ${widget.article.url}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing functionality not fully implemented.'),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No link available to share.')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0), // Add padding below app bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip (moved above headline)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Wrap(
              spacing:
                  8, // Spacing between chips if multiple categories were shown
              children: [
                if (widget.article.category.isNotEmpty &&
                    widget.article.category != 'NEWS')
                  Chip(
                    label: Text(
                      widget.article.category, // Already uppercase from model
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                // Add more chips here if needed (e.g., for allCategories)
              ],
            ),
          ),

          // Headline
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Text(
              widget.article.headline,
              style: TextStyle(
                fontSize: 24, // Slightly larger headline
                fontWeight: FontWeight.bold, // Bold
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),

          // Source and date
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                // Source Icon
                if (widget.article.sourceIcon.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: CachedNetworkImage(
                      imageUrl: widget.article.sourceIcon,
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => SizedBox.shrink(),
                    ),
                  ),
                // Source Name
                Expanded(
                  child: Text(
                    widget.article.sourceName,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500, // Medium weight
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 10),
                // Formatted Date
                Text(
                  _formatDate(widget.article.publishedAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),

          // Author (optional)
          if (widget.article.author.isNotEmpty &&
              widget.article.author != 'Unknown')
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[200],
                    child: Icon(
                      Icons.person_outline,
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
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Image (with some margin)
          if (widget.article.imageUrl.isNotEmpty)
            Container(
              width: double.infinity,
              height: 240, // Slightly taller image
              margin: EdgeInsets.only(
                top: 16.0,
                bottom: 8.0,
              ), // Add vertical margin
              child: CachedNetworkImage(
                imageUrl: widget.article.imageUrl,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey[500],
                        size: 40,
                      ),
                    ),
              ),
            ),
          SizedBox(height: 8.0), // Space before content starts
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Directly use the content passed in the article object
    final String content = widget.article.content;

    // Basic check if content seems empty or placeholder
    if (content.isEmpty || content.length < 20) {
      // Adjust length threshold if needed
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Text(
          'No detailed content available for this article preview. Try reading on the original website.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            _formatContentParagraphs(content)
                .map(
                  (paragraph) => Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      paragraph,
                      style: TextStyle(
                        fontSize: 16.5,
                        color: Color(0xFF333333),
                        height: 1.6,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildSourceInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey[300], height: 20),
          SizedBox(height: 12),
          Text(
            'Source: ${widget.article.sourceName}',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            icon: Icon(Icons.open_in_new, size: 18),
            label: Text('Read Full Article Online'),
            onPressed: () => _launchURL(widget.article.url),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Rounded button
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    // Show countries as tags if available
    if (widget.article.countries.isEmpty) {
      return SizedBox.shrink(); // Don't show section if no countries
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Published In:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children:
                widget.article.countries
                    .map(
                      (country) => Chip(
                        label: Text(
                          country
                              .toUpperCase(), // Ensure country codes/names are uppercase
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: Colors.grey[200],
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
          ),
          SizedBox(height: 16), // Space after tags
        ],
      ),
    );
  }

  Widget _buildRelatedNews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Related News',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Optional: Add "Load More" button for related articles
              if (_relatedNextPageToken != null && !_isLoadingRelated)
                TextButton(
                  onPressed: _fetchMoreRelatedArticles,
                  child: Text('Load More'),
                ),
            ],
          ),
        ),

        // Show loading indicator or error message for related articles
        if (_isLoadingRelated &&
            _relatedArticles.isEmpty) // Only show initial loading
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_errorMessage.isNotEmpty && _relatedArticles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Center(
              child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
            ),
          ),

        // Show related articles list if not loading and no error (or if loading more)
        if (_relatedArticles.isNotEmpty)
          Container(
            height: 210, // Increased height slightly
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: 12,
              ), // Padding for the list itself
              itemCount:
                  _relatedArticles.length +
                  (_isLoadingRelated && _relatedNextPageToken != null
                      ? 1
                      : 0), // Add space for loader when loading more
              itemBuilder: (context, index) {
                if (index == _relatedArticles.length &&
                    _isLoadingRelated &&
                    _relatedNextPageToken != null) {
                  // Show loading indicator at the end while loading more
                  return Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  );
                }
                if (index >= _relatedArticles.length) {
                  return SizedBox.shrink(); // Should not happen
                }

                final article = _relatedArticles[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to the selected related article detail screen
                    // Use pushReplacement if you don't want to stack detail screens infinitely
                    Navigator.pushReplacement(
                      // or push
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => NewsDetailScreen(article: article),
                      ),
                    );
                  },
                  child: Container(
                    width: 180, // Slightly narrower cards
                    margin: EdgeInsets.symmetric(
                      horizontal: 6,
                    ), // Adjust spacing
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child:
                                article.imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                      imageUrl: article.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Icon(
                                            Icons.article,
                                            color: Colors.grey[500],
                                            size: 30,
                                          ),
                                    )
                                    : Center(
                                      child: Icon(
                                        Icons.article,
                                        color: Colors.grey[500],
                                        size: 30,
                                      ),
                                    ), // Placeholder icon
                          ),
                        ),
                        // Content
                        Expanded(
                          // Allow text to take remaining space
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center, // Center text vertically
                              children: [
                                Text(
                                  article.headline,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5, // Adjusted size
                                    color: Colors.black87,
                                  ),
                                  maxLines: 3, // Allow more lines
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  article.category
                                      .toUpperCase(), // Show category
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        // Show message if no related articles found after loading
        if (!_isLoadingRelated &&
            _relatedArticles.isEmpty &&
            _errorMessage.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Center(
              child: Text(
                'No related articles found.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
      ],
    );
  }

  // --- Helper Methods ---

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Date unknown';

    try {
      final DateTime? date = DateTime.tryParse(
        dateString,
      ); // Use tryParse for safety
      if (date != null) {
        // Check if it's today or yesterday for more relative formatting
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays == 0 && now.day == date.day) {
          return 'Today, ${DateFormat.jm().format(date)}'; // e.g., Today, 5:30 PM
        } else if (difference.inDays == 1 ||
            (difference.inDays == 0 && now.day != date.day)) {
          // Handles yesterday or crossing midnight
          return 'Yesterday, ${DateFormat.jm().format(date)}'; // e.g., Yesterday, 10:15 AM
        } else if (difference.inDays < 7) {
          return DateFormat(
            'EEEE, MMM d',
          ).format(date); // e.g., Tuesday, Jun 11
        } else {
          return DateFormat('MMM d, yyyy').format(date); // e.g., Jun 11, 2024
        }
      }
    } catch (e) {
      print('Error parsing date: $dateString - $e');
      // Fallback for unexpected formats
      return dateString.split(' ')[0]; // Try to show at least the date part
    }
    return 'Date unknown'; // Fallback if parsing fails
  }

  List<String> _formatContentParagraphs(String content) {
    if (content.isEmpty) {
      return ["No content available."];
    }

    // Replace potential multiple newlines/breaks with a single one for splitting
    content = content.replaceAll(RegExp(r'\n{2,}'), '\n').trim();

    // Split content by newline character
    List<String> paragraphs =
        content
            .split('\n')
            .map(
              (p) => p.trim(),
            ) // Trim whitespace from each potential paragraph
            .where(
              (p) => p.isNotEmpty && p.length > 10,
            ) // Filter out very short lines/empty strings
            .toList();

    // Add a warning if the content seems truncated (common with API previews)
    // Newsdata.io doesn't typically use '[+]', check for ending ellipsis '...'
    if (content.endsWith('...') && paragraphs.isNotEmpty) {
      paragraphs.add(
        '(Article preview may be truncated. Read the full article online for complete content.)',
      );
    }

    if (paragraphs.length <= 2 && content.length > 300) {
      List<String> sentenceParagraphs = [];
      RegExp sentenceEnd = RegExp(r'(?<=[.?!])\s+');
      List<String> sentences = content.split(sentenceEnd);
      String currentParagraph = '';
      for (String sentence in sentences) {
        if ((currentParagraph + sentence).length < 400 ||
            currentParagraph.isEmpty) {
          currentParagraph += (currentParagraph.isEmpty ? '' : ' ') + sentence;
          if (!'.?!'.contains(sentence.trim().characters.last)) {
            // This part is tricky and might add extra dots. Use with caution.
            // It might be better to just split and not try to re-add punctuation.
          }
        } else {
          sentenceParagraphs.add(currentParagraph.trim());
          currentParagraph = sentence;
        }
      }
      if (currentParagraph.isNotEmpty) {
        //
        sentenceParagraphs.add(currentParagraph.trim());
      }

      if (sentenceParagraphs.length > paragraphs.length) {
        paragraphs = sentenceParagraphs;
      }
    }

    if (paragraphs.isEmpty) {
      return [content];
    }

    return paragraphs;
  }
}
