class CourseItem {
  final String id;
  final String title;
  final String? description;
  final String? subject;
  final String? grade;
  final String? language;
  final String? youtubeUrl;
  final int? courseId;
  final String? thumbnailUrl;
  final int? duration; // in seconds, if available
  final String? type; // e.g., 'video'

  CourseItem({
    required this.id,
    required this.title,
    this.description,
    this.subject,
    this.grade,
    this.language,
    this.youtubeUrl,
    this.courseId,
    this.thumbnailUrl,
    this.duration,
    this.type,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    // Helper to extract string from multiple possible keys
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

    // Helper to extract int from multiple possible keys
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

    // Extract YouTube video ID from URL
    String? extractYouTubeVideoId(String? url) {
      if (url == null) return null;
      final patterns = [
        RegExp(r'v=([a-zA-Z0-9_-]{11})'),
        RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
        RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      ];
      for (final pattern in patterns) {
        final match = pattern.firstMatch(url);
        if (match != null && match.groupCount >= 1) {
          return match.group(1);
        }
      }
      if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
        return url;
      }
      return null;
    }

    final videoId = extractYouTubeVideoId(getString(['youtubeUrl', 'url', 'videoUrl']));
    final thumbnail = videoId != null ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg' : null;

    return CourseItem(
      id: getString(['courseId', 'id', '_id'])?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: getString(['courseName', 'title', 'name']) ??
          'Untitled',
      description: getString(['description', 'desc', 'summary', 'excerpt']),
      subject: getString(['subject']),
      grade: getString(['grade']),
      language: getString(['language', 'lang']),
      youtubeUrl: getString(['youtubeUrl', 'url', 'videoUrl']),
      courseId: getInt(['courseId', 'id']),
      thumbnailUrl: thumbnail,
      duration: getInt(['duration', 'durationSeconds', 'length']),
      type: 'video', // All e-Thaksalawa items are videos
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'grade': grade,
      'language': language,
      'youtubeUrl': youtubeUrl,
      'courseId': courseId,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'type': type,
    };
  }

  @override
  String toString() {
    return 'CourseItem{id: $id, title: $title, subject: $subject, grade: $grade, language: $language}';
  }
}
