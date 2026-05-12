import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/pdf_model.dart';
import '../models/video_model.dart';
import 'youtube_api_service.dart';

class ApiService {
  // ==================== PDF Methods ====================

  static Future<PaginatedResult<PdfItem>> fetchPdfsByCategory(String category, {int page = 1}) async {
    try {
      final uri = Uri.https(
        'v0-json-url-service.vercel.app',
        '/api/scrape/$category',
        {'page': page.toString()},
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'LearnItApp/1.0 (Flutter)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('[$category] HTTP ${response.statusCode}: ${response.body.substring(0, min(500, response.body.length))}');
        throw Exception('Failed to load $category: ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);
      debugPrint('[$category] Page $page - Raw: ${response.body.substring(0, min(500, response.body.length))}');

      List<dynamic>? items = _extractItems(decoded);
      if (items == null || items.isEmpty) {
        debugPrint('[$category] No items found on page $page');
        return PaginatedResult<PdfItem>(items: [], currentPage: page, totalPages: page);
      }

      final result = <PdfItem>[];
      for (final json in items) {
        if (json is Map<String, dynamic>) {
          try {
            final item = PdfItem.fromJson(json);
            result.add(PdfItem(
              id: item.id,
              title: item.title,
              description: item.description,
              thumbnailUrl: item.thumbnailUrl,
              pdfUrl: item.pdfUrl,
              pageCount: item.pageCount,
              category: formatCategoryName(category),
            ));
          } catch (e) {
            debugPrint('[$category] Parse error: $e');
          }
        }
      }

      int totalPages = 1;
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final pagination = data['pagination'];
          if (pagination is Map<String, dynamic>) {
            totalPages = pagination['totalPages'] ?? 1;
          }
        }
      }

      debugPrint('[$category] Parsed ${result.length} items on page $page/$totalPages');
      return PaginatedResult<PdfItem>(
        items: result,
        currentPage: page,
        totalPages: totalPages,
      );
    } catch (e) {
      throw Exception('Network error fetching $category page $page: $e');
    }
  }

  static List<dynamic>? _extractItems(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final items = data['items'];
        if (items is List) return items;
      }
    } else if (decoded is List) {
      return decoded;
    }
    return _extractItemsRecursive(decoded);
  }

  static List<dynamic>? _extractItemsRecursive(dynamic value) {
    if (value is Map<String, dynamic>) {
      final pdfKeys = ['title', 'id', 'name', 'url', 'thumbnail', 'pdf', 'description'];
      final hasKey = value.keys.any((k) => pdfKeys.any((pk) => k.toLowerCase().contains(pk)));
      if (hasKey) return [value];
      for (final v in value.values) {
        final res = _extractItemsRecursive(v);
        if (res != null && res.isNotEmpty) return res;
      }
      return null;
    } else if (value is List) {
      final all = <dynamic>[];
      for (final item in value) {
        final res = _extractItemsRecursive(item);
        if (res != null) all.addAll(res);
      }
      return all.isNotEmpty ? all : null;
    }
    return null;
  }

  static String formatCategoryName(String category) {
    switch (category) {
      case 'past-papers': return 'Past Papers';
      case 'model-papers': return 'Model Papers';
      case 'teacher-guides': return 'Teacher Guides';
      case 'term-test-papers': return 'Term Tests';
      case 'text-books': return 'Text Books';
      default:
        return category.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }

  static Future<List<PdfItem>> fetchPdfs() async {
    return fetchPdfsByCategory('past-papers').then((r) => r.items);
  }

  // ==================== Video Methods ====================

  // Fetch videos using YouTube Data API v3 with fallback to RSS
  static Future<PaginatedResult<VideoItem>> fetchVideos() async {
    try {
      // If YouTube API is configured, use it
      if (AppConfig.useYouTubeApi) {
        final youtubeService = YouTubeApiService();
        final allVideos = <VideoItem>[];
        final seenIds = <String>{};

        // Channel IDs for the two YouTube channels
        const channels = [
          {'id': 'UCnY7v189bwoSTFFYD_PNWhQ', 'name': 'Channel NIE'},
          {'id': 'UC9R2DswH8ZJ8r12lyvTLkDw', 'name': 'Ethaksalawa'},
        ];

        for (final channel in channels) {
          try {
            final videos = await youtubeService.getChannelVideos(
              channel['id'] as String,
              maxResults: 15,
            );
            for (final v in videos) {
              if (!seenIds.contains(v.videoId)) {
                allVideos.add(v);
                seenIds.add(v.videoId);
              }
            }
          } catch (e) {
            debugPrint('Error fetching channel ${channel['id']} via API: $e');
          }
        }

        if (allVideos.isNotEmpty) {
          debugPrint('Fetched ${allVideos.length} videos via YouTube API');
          return PaginatedResult<VideoItem>(
            items: allVideos,
            currentPage: 1,
            totalPages: 1,
          );
        }
      }

      // Fallback to RSS fetching if API not configured or returned no results
      debugPrint('Falling back to RSS fetch');
      final videos = await _fetchVideosFromRSSFallback();
      return PaginatedResult<VideoItem>(
        items: videos,
        currentPage: 1,
        totalPages: 1,
      );
    } catch (e) {
      throw Exception('Network error fetching videos: $e');
    }
  }

  // Fetch videos from YouTube RSS feed for a channel (fallback method)
  static Future<List<VideoItem>> _fetchVideosFromRSSFallback() async {
    try {
      // Channel IDs for the two YouTube channels
      const channels = [
        {'id': 'UCnY7v189bwoSTFFYD_PNWhQ', 'name': 'Channel NIE'},
        {'id': 'UC9R2DswH8ZJ8r12lyvTLkDw', 'name': 'Ethaksalawa'},
      ];

      final allVideos = <VideoItem>[];
      final seenIds = <String>{};

      for (final channel in channels) {
        try {
          final uri = Uri.https(
            'www.youtube.com',
            '/feeds/videos.xml',
            {'channel_id': channel['id'] as String},
          );
          final response = await http.get(
            uri,
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'application/xml',
            },
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode != 200) {
            debugPrint('[RSS ${channel['id']}] HTTP ${response.statusCode}');
            continue;
          }

          final body = response.body;
          debugPrint('[RSS ${channel['id']}] Response length: ${body.length}');
          
          // Check if response contains valid feed
          if (!body.contains('<feed') && !body.contains('<entry')) {
            debugPrint('[RSS ${channel['id']}] Invalid feed or empty response');
            continue;
          }

          final entryRegex = RegExp(r'<entry[^>]*>(.*?)</entry>', dotAll: true);
          final entries = entryRegex.allMatches(body);
          debugPrint('[RSS ${channel['id']}] Found ${entries.length} entries');

          const maxVideos = 15; // Limit per channel
          int addedCount = 0;
          for (final entryMatch in entries) {
            if (allVideos.length >= maxVideos * channels.length) break;
            final entry = entryMatch.group(1) ?? '';
            try {
              // Use flexible regex that allows attributes in tags
              final idMatch = RegExp(r'<yt:videoId[^>]*>([^<]+)</yt:videoId>').firstMatch(entry);
              final titleMatch = RegExp(r'<title[^>]*>([^<]+)</title>').firstMatch(entry);
              final thumbMatch = RegExp(r'<media:thumbnail[^>]*url="([^"]+)"').firstMatch(entry);

              if (idMatch != null && titleMatch != null) {
                final videoId = idMatch.group(1)!;
                var title = titleMatch.group(1)!;
                // Clean up CDATA sections if present
                if (title.startsWith('<![CDATA[') && title.endsWith(']]>')) {
                  title = title.substring(9, title.length - 3);
                }
                final thumbnailUrl = thumbMatch?.group(1) ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
                if (!seenIds.contains(videoId)) {
                  allVideos.add(VideoItem(
                    id: videoId,
                    title: title,
                    videoId: videoId,
                    thumbnailUrl: thumbnailUrl,
                    channelName: channel['name'],
                    description: null,
                    durationSeconds: null,
                  ));
                  seenIds.add(videoId);
                  addedCount++;
                }
              }
            } catch (e) {
              debugPrint('[RSS ${channel['id']}] Entry parse error: $e');
            }
           }

           debugPrint('[RSS ${channel['id']}] Added $addedCount videos');
         } catch (e) {
           debugPrint('Error fetching channel ${channel['id']}: $e');
         }
       }

      debugPrint('Fetched ${allVideos.length} videos via RSS fallback');
      return allVideos;
    } catch (e) {
      debugPrint('RSS fetch error: $e');
      return [];
    }
  }
}

class PaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;

  PaginatedResult({required this.items, required this.currentPage, required this.totalPages});
}
