import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class NewsApiService {
  static final String _apiKey = dotenv.env['NEWSDATA_API_KEY'] ?? 'API_KEY_NOT_FOUND';

  static const String _baseUrl = "https://newsdata.io/api/1/news";
  NewsApiService() {
     if (_apiKey == 'API_KEY_NOT_FOUND' || _apiKey.isEmpty) {
        print("FATAL ERROR: NEWSDATA_API_KEY not found in .env file or failed to load.");
        // nanti lempar Exception di sini
        // throw Exception("API Key configuration error.");
     }
  }


  
  Future<NewsApiResponse> fetchNews({
    String category = 'business',
    String language = 'en',
    String? page,
  }) async {

    // (Opsional) Pemeriksaan tambahan di sini jika tidak di constructor
    // if (_apiKey == 'API_KEY_NOT_FOUND' || _apiKey.isEmpty) {
    //    throw Exception("Cannot fetch news: API Key is missing.");
    // }


    final Map<String, String> queryParams = {
      'apikey': _apiKey, 
      'language': language,
      if (category.isNotEmpty && category.toLowerCase() != 'urutkan')
         'category': category.toLowerCase(),
      if (page != null && page.isNotEmpty) 'page': page,
    };

    final Uri uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    print("Fetching news from: $uri"); // Hati-hati, ini bakal ngeprint API Key ke konsol kalau aktif

    try {
      final response = await http.get(uri);      
       if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        final newsResponse = NewsApiResponse.fromJson(jsonData);

        if (newsResponse.status == 'success') {
             print("Successfully fetched ${newsResponse.articles.length} articles.");
             return newsResponse;
        } else {
             print("API Error: ${newsResponse.errorMessage}");
             throw Exception('API Error: ${newsResponse.errorMessage ?? "Unknown API error"}');
        }

      } else {
        print("HTTP Error: ${response.statusCode} - ${response.reasonPhrase}");
        throw Exception('Failed to load news (HTTP ${response.statusCode})');
      }
    } catch (e) {
      print("Error fetching or parsing news: $e");
      throw Exception('Failed to fetch news. Check connection or API response.');
    }
  }
}