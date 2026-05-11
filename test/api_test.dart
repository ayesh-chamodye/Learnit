import 'package:flutter_test/flutter_test.dart';
import 'package:learnit/services/api_service.dart';
import 'package:learnit/models/pdf_model.dart';

void main() {
  final allCategories = [
    'past-papers',
    'model-papers',
    'teacher-guides',
    'term-test-papers',
    'text-books',
  ];

  for (final cat in allCategories) {
    test('ApiService fetches $cat', () async {
      final result = await ApiService.fetchPdfsByCategory(cat);
      expect(result.items, isNotEmpty, reason: 'Should have items for $cat');
      print('[$cat] Fetched ${result.items.length} items (page ${result.currentPage}/${result.totalPages}). First: ${result.items.first.title}');
    });
  }
}
