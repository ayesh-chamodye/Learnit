import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/course_model.dart';

class EthaksalawaService {
  static const String _baseUrl = AppConfig.ethaksalawaBaseUrl;
  static const String _apiPath = AppConfig.ethaksalawaApiPath;

  /// Fetch courses with optional filters directly from API
  /// [language]: Sinhala, English, Tamil
  /// [subject]: science, maths, etc.
  /// [grade]: 06, 07, 08, etc.
  static Future<List<CourseItem>> fetchCourses({
    String? language,
    String? subject,
    String? grade,
  }) async {
    // Build URI with query parameters
    final uri = Uri.https(
      _baseUrl,
      _apiPath,
      {
        if (language != null) 'language': language,
        if (subject != null) 'subject': subject.toLowerCase(),
        if (grade != null) 'grade': grade,
      },
    );

    debugPrint('[Ethaksalawa] Fetching: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'LearnItApp/1.0 (Flutter)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('[Ethaksalawa] HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 500))}');
        throw Exception('Failed to load courses: ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);
      debugPrint('[Ethaksalawa] Raw response length: ${response.body.length}');

      // Extract 'videos' array from response
      final videos = _extractVideosArray(decoded);
      if (videos == null || videos.isEmpty) {
        debugPrint('[Ethaksalawa] No videos found in response');
        return [];
      }

      // Parse into CourseItem objects
      final courses = <CourseItem>[];
      for (final json in videos) {
        if (json is Map<String, dynamic>) {
          try {
            final course = CourseItem.fromJson(json);
            courses.add(course);
          } catch (e) {
            debugPrint('[Ethaksalawa] Parse error: $e');
          }
        }
      }

      debugPrint('[Ethaksalawa] Parsed ${courses.length} courses (before dedup)');

      // Deduplicate by youtubeUrl to remove duplicates
      final seenUrls = <String>{};
      final uniqueCourses = <CourseItem>[];
      for (final course in courses) {
        final url = course.youtubeUrl;
        if (url != null) {
          if (!seenUrls.contains(url)) {
            seenUrls.add(url);
            uniqueCourses.add(course);
          }
        } else {
          uniqueCourses.add(course);
        }
      }

      debugPrint('[Ethaksalawa] After dedup: ${uniqueCourses.length} courses');
      return uniqueCourses;
    } catch (e) {
      debugPrint('[Ethaksalawa] Network error: $e');
      rethrow;
    }
  }

  /// Extract 'videos' array from API response.
  /// Handles both { "videos": [...] } and direct array responses.
  static List<dynamic>? _extractVideosArray(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final videos = decoded['videos'];
      if (videos is List) return videos;
      // Also check alternative keys
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final items = data['items'] ?? data['courses'] ?? data['results'];
        if (items is List) return items;
      }
    }
    return null;
  }

  /// Get available subjects
  static List<String> getAvailableSubjects() {
    return [
      'Mathematics',
      'Science',
      'Geography',
      'Civic Education',
      'Health & Physical Education',
      'History',
      'Buddhism',
      'Hinduism',
      'Islam',
      'Christianity',
      'Sinhala',
      'English',
      'Tamil',
      'ICT',
      'Aesthetic',
    ];
  }

  static List<String> getAvailableGrades() {
    return List.generate(13, (i) => (i + 1).toString().padLeft(2, '0')).toList();
  }

  static List<String> getAvailableLanguages() {
    return ['Sinhala', 'English', 'Tamil'];
  }

  /// Format grade for display
  static String formatGrade(String? grade) {
    if (grade == null) return 'All Grades';
    return 'Grade $grade';
  }

  /// Format subject for display
  static String formatSubject(String? subject) {
    if (subject == null) return 'All Subjects';
    return subject;
  }
}
