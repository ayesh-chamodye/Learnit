import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import 'api_service.dart';

/// Service for fetching courses directly from API (no offline storage)
class EthaksalawaService {
  static const String _baseUrl = 'https://v0-json-url-service.vercel.app/api/e-thaksalawa';
  // Use a Dio instance with longer timeout for this slow API
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 300),
      receiveTimeout: const Duration(seconds: 300),
      sendTimeout: const Duration(seconds: 300),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'LearnItApp/1.0 (Flutter)',
      },
    ),
  );

  static Future<PaginatedResult<CourseItem>> fetchCourses({
    String? grade,
    String? language,
    String? subject,
    String? searchQuery,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      // Build query parameters - only page, others are filters
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (grade != null && grade.isNotEmpty) queryParams['grade'] = grade;
      if (language != null && language.isNotEmpty) queryParams['language'] = language;
      if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
      if (searchQuery != null && searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

      final response = await _dio.get(
        _baseUrl,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }

      if (kDebugMode) {
        debugPrint('[Ethaksalawa] Request URL: ${response.requestOptions.uri}');
        debugPrint('[Ethaksalawa] Filters: grade=$grade, language=$language, subject=$subject, search=$searchQuery, page=$page');
      }

      final dynamic decoded = response.data;
      List<dynamic> items = [];

      // The API returns videos at the top level
      if (decoded is Map<String, dynamic>) {
        if (kDebugMode) {
          debugPrint('[Ethaksalawa] Response keys: ${decoded.keys}');
          debugPrint('[Ethaksalawa] Total: ${decoded['total']}, totalPages: ${decoded['totalPages']}');
        }
        items = decoded['videos'] ?? [];
        if (kDebugMode) {
          debugPrint('[Ethaksalawa] Found ${items.length} videos in response');
        }
        // Also check for nested data structure
        if (items.isEmpty) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            items = data['items'] ?? data['videos'] ?? [];
          }
        }
      } else if (decoded is List) {
        items = decoded;
      } else {
        items = [];
      }

      final courses = items
          .whereType<Map<String, dynamic>>()
          .map((item) => CourseItem.fromJson(item))
          .toList();

      if (kDebugMode) {
        debugPrint('[Ethaksalawa] Parsed ${courses.length} courses from ${items.length} items');
        for (final c in courses.take(3)) {
          debugPrint('[Ethaksalawa] Sample: grade=${c.grade}, lang=${c.language}, subject=${c.subject}');
        }
      }

      // API already applies filters server-side, so we use the courses directly
      // However, we still need to apply searchQuery locally if provided
      var filtered = courses;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        filtered = filtered.where((c) =>
            c.title.toLowerCase().contains(q) ||
            (c.subject?.toLowerCase() ?? '').contains(q) ||
            (c.description?.toLowerCase() ?? '').contains(q)).toList();
      }

      if (kDebugMode) {
        debugPrint('[Ethaksalawa] After any local filtering: ${filtered.length} / ${courses.length} courses');
      }

      // Try to get pagination info from API response
      int totalPages = 1;
      int currentPage = page;
      if (decoded is Map<String, dynamic>) {
        totalPages = (decoded['totalPages'] ?? 1) as int;
        currentPage = (decoded['currentPage'] ?? page) as int;
      }

      if (kDebugMode) {
        debugPrint('[Ethaksalawa] Fetched ${courses.length} courses on page $page/$totalPages, filtered to ${filtered.length}');
      }

      return PaginatedResult<CourseItem>(
        items: filtered,
        currentPage: currentPage,
        totalPages: totalPages,
      );
    } catch (e) {
      debugPrint('[Ethaksalawa] Error: $e');
      rethrow;
    }
  }

  static Future<void> forceRefresh() async {
    // No cache to refresh
  }

  static Future<bool> isCacheStale() async {
    return false;
  }

  static Future<void> refreshIfNeeded() async {
    // No offline cache
  }

  static Future<void> downloadFullDataset() async {
    // No download needed
  }

  static Future<void> downloadForOfflineUse() async {
    // No offline use
  }

  static Future<List<String>> getAvailableGrades() async {
    final result = await fetchCourses();
    final grades = result.items
        .map((c) => c.grade)
        .where((g) => g != null && g.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
    return grades;
  }

  static Future<List<String>> getAvailableLanguages() async {
    final result = await fetchCourses();
    final languages = result.items.map((c) => c.language).where((l) => l != null && l.isNotEmpty).cast<String>().toSet().toList()..sort();
    return languages;
  }

  static Future<List<String>> getAvailableSubjects() async {
    final result = await fetchCourses();
    final subjects = result.items.map((c) => c.subject).where((s) => s != null && s.isNotEmpty).cast<String>().toSet().toList()..sort();
    return subjects;
  }

  static Future<Map<String, int>> getStats() async {
    final result = await fetchCourses();
    return {'courses': result.items.length};
  }

  static void clearCache() {
    // No cache
  }

  static Future<void> resetDatabase() async {
    // No database
  }

  static String formatSubject(String subject) {
    return subject.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}