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
      final items = await ApiService.fetchPdfsByCategory(cat);
      expect(items, isNotEmpty, reason: 'Should have items for $cat');
      print('[$cat] Fetched ${items.length} items. First: ${items.first.title}');
    });
  }
}
