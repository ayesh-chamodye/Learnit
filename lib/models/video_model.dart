class VideoItem {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String videoId; // YouTube video ID
  final String? channelName;
  final int? durationSeconds;
  final String? category;

  VideoItem({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.videoId,
    this.channelName,
    this.durationSeconds,
    this.category,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    String? getString(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key)) {
          final value = json[key];
          if (value != null) return value.toString();
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

    return VideoItem(
      id: getString(['id', 'videoId', 'video_id']) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: getString(['title', 'name', 'videoTitle']) ?? 'Untitled Video',
      description: getString(['description', 'desc', 'summary']),
      thumbnailUrl: getString(['thumbnailUrl', 'thumbnail', 'thumb', 'image']),
      videoId: getString(['videoId', 'video_id', 'youtubeId', 'id']) ?? '',
      channelName: getString(['channelName', 'channel', 'author', 'uploader']),
      durationSeconds: getInt(['durationSeconds', 'duration', 'length']),
      category: getString(['category', 'type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoId': videoId,
      'channelName': channelName,
      'durationSeconds': durationSeconds,
      'category': category,
    };
  }
}
