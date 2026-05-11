class PdfItem {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? pdfUrl;
  final int? pageCount;
  final String? category;

  PdfItem({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.pdfUrl,
    this.pageCount,
    this.category,
  });

  factory PdfItem.fromJson(Map<String, dynamic> json) {
    // Helper to extract value from multiple possible keys
    String? getString(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key)) {
          final value = json[key];
          if (value != null) {
            return value.toString();
          }
        }
      }
      return null;
    }

    int? getInt(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key)) {
          final value = json[key];
          if (value is int) return value;
          if (value is String) return int.tryParse(value);
          if (value is double) return value.toInt();
        }
      }
      return null;
    }

    return PdfItem(
      id: getString(['id', '_id', 'paperId', 'bookId', 'resourceId']) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: getString(['title', 'name', 'paperTitle', 'bookTitle', 'resourceTitle', 'subject']) ??
          'Untitled',
      description: getString(['description', 'desc', 'summary', 'excerpt']),
      thumbnailUrl: getString(['thumbnailUrl', 'thumbnail', 'image', 'cover', 'coverImage', 'imageUrl']),
      pdfUrl: getString(['pdfUrl', 'url', 'downloadUrl', 'link', 'fileUrl', 'documentUrl']),
      pageCount: getInt(['pageCount', 'pages', 'numPages', 'pageCount']),
      category: getString(['category', 'type', 'resourceType']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'pdfUrl': pdfUrl,
      'pageCount': pageCount,
      'category': category,
    };
  }
}
