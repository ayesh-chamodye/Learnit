import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/video_model.dart';
import 'api_client.dart';

/// Service for interacting with YouTube Data API v3
/// Documentation: https://developers.google.com/youtube/v3/docs
class YouTubeApiService {
  final String _apiKey;
  final String _baseUrl;

  YouTubeApiService({String? apiKey})
      : _apiKey = apiKey ?? AppConfig.youtubeApiKey,
        _baseUrl = AppConfig.youtubeApiBaseUrl;

  /// Check if the API is properly configured
  bool get isConfigured => _apiKey.isNotEmpty && _apiKey != 'YOUR_YOUTUBE_API_KEY_HERE';

  /// Search for videos using the YouTube Data API
  ///
  /// [query] - Search query string
  /// [maxResults] - Maximum number of results to return (1-50)
  /// [order] - Sort order: 'date', 'rating', 'relevance', 'title', 'videoCount', 'viewCount'
  /// [type] - Resource type: 'video', 'channel', 'playlist'
  Future<List<VideoItem>> searchVideos(
    String query, {
    int maxResults = 25,
    String order = 'date',
    String type = 'video',
  }) async {
    if (!isConfigured) {
      debugPrint('YouTube API not configured. Falling back to RSS.');
      return [];
    }

    try {
      final uri = Uri.https(
        _baseUrl,
        '/youtube/v3/search',
        {
          'part': 'snippet',
          'q': query,
          'maxResults': maxResults.toString(),
          'order': order,
          'type': type,
          'key': _apiKey,
          'relevanceLanguage': 'en',
        },
      );

      final response = await ApiClient().dio.getUri(
        uri,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Accept-Encoding': 'gzip, deflate',
          },
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('YouTube API search error: HTTP ${response.statusCode} - ${response.data}');
        return [];
      }

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) {
        return [];
      }

      return items.map((item) => _convertSearchResult(item)).whereType<VideoItem>().toList();
    } catch (e) {
      debugPrint('YouTube API search exception: $e');
      return [];
    }
  }

  /// Get detailed information for a list of video IDs
  ///
  /// [videoIds] - List of YouTube video IDs (max 50 per request)
  Future<List<VideoItem>> getVideosByIds(List<String> videoIds) async {
    if (!isConfigured || videoIds.isEmpty) {
      return [];
    }

    try {
      // YouTube API allows up to 50 IDs per request
      final idsParam = videoIds.take(50).join(',');

      final uri = Uri.https(
        _baseUrl,
        '/youtube/v3/videos',
        {
          'part': 'snippet,contentDetails,statistics',
          'id': idsParam,
          'key': _apiKey,
        },
      );

      final response = await ApiClient().dio.getUri(
        uri,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Accept-Encoding': 'gzip, deflate',
          },
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('YouTube API getVideosByIds error: HTTP ${response.statusCode}');
        return [];
      }

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) {
        return [];
      }

      return items.map((item) => _convertVideoResult(item)).whereType<VideoItem>().toList();
    } catch (e) {
      debugPrint('YouTube API getVideosByIds exception: $e');
      return [];
    }
  }

  /// Get all videos from a specific YouTube channel
  ///
  /// [channelId] - YouTube channel ID (starts with UC...)
  /// [maxResults] - Maximum number of uploads to fetch (max 50 per request)
  Future<List<VideoItem>> getChannelVideos(String channelId, {int maxResults = 25}) async {
    if (!isConfigured) {
      return [];
    }

    try {
      // First, get the channel's upload playlist ID
      final uploadPlaylistId = await _getChannelUploadPlaylist(channelId);
      if (uploadPlaylistId == null) {
        return [];
      }

      // Then fetch videos from the upload playlist
      return await _getPlaylistVideos(uploadPlaylistId, maxResults: maxResults);
    } catch (e) {
      debugPrint('YouTube API getChannelVideos exception: $e');
      return [];
    }
  }

  /// Get videos from a specific playlist
  Future<List<VideoItem>> _getPlaylistVideos(String playlistId, {int maxResults = 25}) async {
    try {
      final uri = Uri.https(
        _baseUrl,
        '/youtube/v3/playlistItems',
        {
          'part': 'snippet,contentDetails',
          'playlistId': playlistId,
          'maxResults': maxResults.toString(),
          'key': _apiKey,
        },
      );

      final response = await ApiClient().dio.getUri(
        uri,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Accept-Encoding': 'gzip, deflate',
          },
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('YouTube API playlist error: HTTP ${response.statusCode}');
        return [];
      }

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) {
        return [];
      }

      return items.map((item) => _convertPlaylistItemResult(item)).whereType<VideoItem>().toList();
    } catch (e) {
      debugPrint('YouTube API _getPlaylistVideos exception: $e');
      return [];
    }
  }

  /// Get the upload playlist ID for a channel
  Future<String?> _getChannelUploadPlaylist(String channelId) async {
    try {
      final uri = Uri.https(
        _baseUrl,
        '/youtube/v3/channels',
        {
          'part': 'contentDetails',
          'id': channelId,
          'key': _apiKey,
        },
      );

      final response = await ApiClient().dio.getUri(
        uri,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Accept-Encoding': 'gzip, deflate',
          },
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('YouTube API channel error: HTTP ${response.statusCode}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) {
        return null;
      }

      final firstItem = items.first as Map<String, dynamic>?;
      final contentDetails = firstItem?['contentDetails'] as Map<String, dynamic>?;
      final relatedPlaylists = contentDetails?['relatedPlaylists'] as Map<String, dynamic>?;
      return relatedPlaylists?['uploads'] as String?;
    } catch (e) {
      debugPrint('YouTube API _getChannelUploadPlaylist exception: $e');
      return null;
    }
  }

  /// Convert search result API item to VideoItem
  VideoItem? _convertSearchResult(dynamic item) {
    try {
      final snippet = item['snippet'] as Map<String, dynamic>?;
      if (snippet == null) return null;

      final videoId = item['id']?['videoId'] as String?;
      if (videoId == null) return null;

      return VideoItem(
        id: videoId,
        title: snippet['title'] ?? 'Untitled',
        description: snippet['description'],
        thumbnailUrl: snippet['thumbnails']?['high']?['url'] ??
            snippet['thumbnails']?['medium']?['url'] ??
            snippet['thumbnails']?['default']?['url'] ??
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        videoId: videoId,
        channelName: snippet['channelTitle'],
        durationSeconds: null, // Search API doesn't return duration
      );
    } catch (e) {
      debugPrint('Error converting search result: $e');
      return null;
    }
  }

  /// Convert video details API item to VideoItem
  VideoItem? _convertVideoResult(dynamic item) {
    try {
      final snippet = item['snippet'] as Map<String, dynamic>?;
      final contentDetails = item['contentDetails'] as Map<String, dynamic>?;

      if (snippet == null) return null;

      final videoId = item['id'] as String?;
      if (videoId == null) return null;

      String? durationStr = contentDetails?['duration'];
      int? durationSeconds;
      if (durationStr != null) {
        durationSeconds = _parseYouTubeDuration(durationStr);
      }

      return VideoItem(
        id: videoId,
        title: snippet['title'] ?? 'Untitled',
        description: snippet['description'],
        thumbnailUrl: snippet['thumbnails']?['high']?['url'] ??
            snippet['thumbnails']?['medium']?['url'] ??
            snippet['thumbnails']?['default']?['url'] ??
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        videoId: videoId,
        channelName: snippet['channelTitle'],
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      debugPrint('Error converting video result: $e');
      return null;
    }
  }

  /// Convert playlist item result to VideoItem
  VideoItem? _convertPlaylistItemResult(dynamic item) {
    try {
      final snippet = item['snippet'] as Map<String, dynamic>?;
      if (snippet == null) return null;

      final videoId = snippet['resourceId']?['videoId'] as String?;
      if (videoId == null) return null;

      return VideoItem(
        id: videoId,
        title: snippet['title'] ?? 'Untitled',
        description: snippet['description'],
        thumbnailUrl: snippet['thumbnails']?['high']?['url'] ??
            snippet['thumbnails']?['medium']?['url'] ??
            snippet['thumbnails']?['default']?['url'] ??
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        videoId: videoId,
        channelName: snippet['channelTitle'],
        durationSeconds: null, // Need separate API call for duration
      );
    } catch (e) {
      debugPrint('Error converting playlist item result: $e');
      return null;
    }
  }

  /// Parse YouTube duration format (e.g., "PT1H2M30S") to seconds
  int _parseYouTubeDuration(String duration) {
    try {
      final pattern = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = pattern.firstMatch(duration);
      if (match == null) return 0;

      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

      return hours * 3600 + minutes * 60 + seconds;
    } catch (e) {
      return 0;
    }
  }
}
