import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/pdf_model.dart';

class ApiService {
  static Future<PaginatedResult<PdfItem>> fetchPdfsByCategory(String category, {int page = 1}) async {
    try {
      final uri = Uri.https(
        'v0-json-url-service-4bgdc0l9m-ayesh-chamodyes-projects.vercel.app',
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

      // Extract totalPages from pagination metadata
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
    // Fallback: search recursively
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
}

class PaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;

  PaginatedResult({required this.items, required this.currentPage, required this.totalPages});
}
