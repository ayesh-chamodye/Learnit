import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/pdf_model.dart';

class ApiService {
  static const String _baseUrl = 'https://v0-json-url-service-4bgdc0l9m-ayesh-chamodyes-projects.vercel.app';

  static Future<List<PdfItem>> fetchPdfsByCategory(String category) async {
    try {
      // Try with full path construction
      final uri = Uri.https('v0-json-url-service-4bgdc0l9m-ayesh-chamodyes-projects.vercel.app', '/api/scrape/$category');
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
      debugPrint('[$category] Raw: ${response.body.substring(0, min(500, response.body.length))}');

      // Primary extraction: { "data": { "items": [...] } }
      List<dynamic>? items = _extractItemsFromKnownStructure(decoded);
      
      // Fallback: generic recursive extraction
      items ??= _extractItemsRecursive(decoded);

      if (items == null || items.isEmpty) {
        debugPrint('[$category] No items found');
        return [];
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

      debugPrint('[$category] Parsed ${result.length} items');
      return result;
    } catch (e) {
      throw Exception('Network error fetching $category: $e');
    }
  }

  static List<dynamic>? _extractItemsFromKnownStructure(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final items = data['items'];
        if (items is List) {
          debugPrint('Found data.items with ${items.length} elements');
          return items;
        }
      }
    }
    return null;
  }

  static List<dynamic>? _extractItemsRecursive(dynamic value) {
    if (value is Map<String, dynamic>) {
      // If the map has keys typical of a PDF item, treat as a single-item list
      final pdfKeyPatterns = ['title', 'id', 'name', 'url', 'thumbnail', 'pdf', 'description'];
      final hasPdfKey = value.keys.any((k) => 
        pdfKeyPatterns.any((pattern) => k.toLowerCase().contains(pattern))
      );
      if (hasPdfKey) return [value];
      
      // Search values recursively for lists
      for (final v in value.values) {
        final result = _extractItemsRecursive(v);
        if (result != null && result.isNotEmpty) return result;
      }
      return null;
    } else if (value is List) {
      // Flatten all PDF-item maps found in the list
      final allItems = <dynamic>[];
      for (final item in value) {
        final result = _extractItemsRecursive(item);
        if (result != null) allItems.addAll(result);
      }
      return allItems.isNotEmpty ? allItems : null;
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
        return category.split('-').map((w) => 
          w[0].toUpperCase() + w.substring(1)
        ).join(' ');
    }
  }

  static Future<List<PdfItem>> fetchPdfs() async {
    return fetchPdfsByCategory('past-papers');
  }
}
