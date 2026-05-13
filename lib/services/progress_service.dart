import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for tracking user learning progress
class LearningProgress {
  final String courseId;
  final String courseTitle;
  final String? thumbnailUrl;
  final bool isCompleted;
  final double progressPercent; // 0.0 to 1.0
  final int? lastPositionSec; // Last watched position in seconds (videos) or page number (PDFs)
  final int? totalDurationSec; // Total video duration in seconds or total pages (PDFs)
  final DateTime firstAccessedAt;
  final DateTime lastAccessedAt;
  final DateTime? completedAt;
  final String contentType; // 'video' or 'pdf'
  final String? contentRef; // videoId (YouTube) for videos, pdfUrl for PDFs

  LearningProgress({
    required this.courseId,
    required this.courseTitle,
    this.thumbnailUrl,
    this.isCompleted = false,
    this.progressPercent = 0.0,
    this.lastPositionSec,
    this.totalDurationSec,
    required this.firstAccessedAt,
    required this.lastAccessedAt,
    this.completedAt,
    this.contentType = 'video',
    this.contentRef,
  });

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      courseId: json['courseId'] as String,
      courseTitle: json['courseTitle'] as String? ?? 'Untitled',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      lastPositionSec: json['lastPositionSec'] as int?,
      totalDurationSec: json['totalDurationSec'] as int?,
      firstAccessedAt: DateTime.fromMillisecondsSinceEpoch(json['firstAccessedAt'] as int? ?? 0),
      lastAccessedAt: DateTime.fromMillisecondsSinceEpoch(json['lastAccessedAt'] as int? ?? 0),
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : null,
      contentType: json['contentType'] as String? ?? 'video', // backward compatibility
      contentRef: json['contentRef'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'thumbnailUrl': thumbnailUrl,
      'isCompleted': isCompleted,
      'progressPercent': progressPercent,
      'lastPositionSec': lastPositionSec,
      'totalDurationSec': totalDurationSec,
      'firstAccessedAt': firstAccessedAt.millisecondsSinceEpoch,
      'lastAccessedAt': lastAccessedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'contentType': contentType,
      'contentRef': contentRef,
    };
  }

  LearningProgress copyWith({
    String? courseId,
    String? courseTitle,
    String? thumbnailUrl,
    bool? isCompleted,
    double? progressPercent,
    int? lastPositionSec,
    int? totalDurationSec,
    DateTime? firstAccessedAt,
    DateTime? lastAccessedAt,
    DateTime? completedAt,
    String? contentType,
    String? contentRef,
  }) {
    return LearningProgress(
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      progressPercent: progressPercent ?? this.progressPercent,
      lastPositionSec: lastPositionSec ?? this.lastPositionSec,
      totalDurationSec: totalDurationSec ?? this.totalDurationSec,
      firstAccessedAt: firstAccessedAt ?? this.firstAccessedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      completedAt: completedAt ?? this.completedAt,
      contentType: contentType ?? this.contentType,
      contentRef: contentRef ?? this.contentRef,
    );
  }
}

/// Service for managing learning progress persistence
class ProgressService {
  static const String _progressKey = 'learning_progress';
  static const String _statsKey = 'learning_stats';

  /// Get all course progress entries
  static Future<List<LearningProgress>> getAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_progressKey);
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) => LearningProgress.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ProgressService: Error loading progress - $e');
      return [];
    }
  }

  /// Get progress for a specific course
  static Future<LearningProgress?> getProgress(String courseId) async {
    final all = await getAllProgress();
    try {
      return all.firstWhere((p) => p.courseId == courseId);
    } catch (_) {
      return null;
    }
  }

  /// Save/update progress for a course
  static Future<void> saveProgress(LearningProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAllProgress();

      // Remove existing entry for this course
      all.removeWhere((p) => p.courseId == progress.courseId);
      all.add(progress);

      final jsonString = jsonEncode(all.map((p) => p.toJson()).toList());
      await prefs.setString(_progressKey, jsonString);
      debugPrint('ProgressService: Saved progress for ${progress.courseTitle}');
    } catch (e) {
      debugPrint('ProgressService: Error saving progress - $e');
    }
  }

  /// Mark a course as completed
  static Future<void> markCompleted(LearningProgress progress) async {
    final updated = progress.copyWith(
      isCompleted: true,
      progressPercent: 1.0,
      completedAt: DateTime.now(),
    );
    await saveProgress(updated);
  }

  /// Update video watch position
  static Future<void> updateWatchPosition(String courseId, int currentSec, int totalSec) async {
    final existing = await getProgress(courseId);
    final now = DateTime.now();

    LearningProgress updated;
    if (existing != null) {
      final progressPercent = totalSec > 0 ? currentSec / totalSec : 0.0;
      final isCompleted = progressPercent >= 0.95; // Mark complete if >95% watched

      updated = existing.copyWith(
        progressPercent: progressPercent,
        lastPositionSec: currentSec,
        totalDurationSec: totalSec,
        lastAccessedAt: now,
        isCompleted: isCompleted,
      );
      if (isCompleted && existing.completedAt == null) {
        updated = updated.copyWith(completedAt: now);
      }
    } else {
      // Create new progress entry
      updated = LearningProgress(
        courseId: courseId,
        courseTitle: '', // Will be set by caller
        thumbnailUrl: null,
        progressPercent: totalSec > 0 ? currentSec / totalSec : 0.0,
        lastPositionSec: currentSec,
        totalDurationSec: totalSec,
        firstAccessedAt: now,
        lastAccessedAt: now,
        isCompleted: false,
      );
    }

    await saveProgress(updated);
  }

  /// Remove progress for a course
  static Future<void> removeProgress(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAllProgress();
      all.removeWhere((p) => p.courseId == courseId);

      final jsonString = jsonEncode(all.map((p) => p.toJson()).toList());
      await prefs.setString(_progressKey, jsonString);
    } catch (e) {
      debugPrint('ProgressService: Error removing progress - $e');
    }
  }

  /// Clear all progress
  static Future<void> clearAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      await prefs.remove(_statsKey);
    } catch (e) {
      debugPrint('ProgressService: Error clearing progress - $e');
    }
  }

  /// Get learning statistics
  static Future<LearningStats> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);
      if (statsJson != null) {
        return LearningStats.fromJson(jsonDecode(statsJson) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('ProgressService: Error loading stats - $e');
    }
    return LearningStats();
  }

  /// Save learning statistics
  static Future<void> _saveStats(LearningStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
    } catch (e) {
      debugPrint('ProgressService: Error saving stats - $e');
    }
  }

  /// Record that a video was started
  static Future<void> recordVideoStart(String courseId, String courseTitle, String? thumbnailUrl, int? totalDuration, String videoId) async {
    final existing = await getProgress(courseId);
    final now = DateTime.now();

    LearningProgress progress;
    if (existing != null) {
      progress = existing.copyWith(
        lastAccessedAt: now,
        courseTitle: courseTitle,
        thumbnailUrl: thumbnailUrl ?? existing.thumbnailUrl,
        totalDurationSec: totalDuration ?? existing.totalDurationSec,
        contentType: 'video',
        contentRef: videoId,
      );
    } else {
      progress = LearningProgress(
        courseId: courseId,
        courseTitle: courseTitle,
        thumbnailUrl: thumbnailUrl,
        firstAccessedAt: now,
        lastAccessedAt: now,
        progressPercent: 0.0,
        totalDurationSec: totalDuration,
        contentType: 'video',
        contentRef: videoId,
      );
    }

    await saveProgress(progress);

    // Update stats
    final stats = await getStats();
    stats.totalVideosWatched += 1;
    stats.lastActiveAt = now;
    await _saveStats(stats);
  }

  /// Record video completion
  static Future<void> recordVideoComplete(String courseId) async {
    final progress = await getProgress(courseId);
    if (progress != null) {
      await markCompleted(progress);
      final stats = await getStats();
      stats.completedVideos += 1;
      await _saveStats(stats);
    }
  }

  /// Record that a PDF was opened/started reading
  static Future<void> recordPdfStart(String pdfId, String title, {String? thumbnailUrl, int? totalPages}) async {
    final existing = await getProgress(pdfId);
    final now = DateTime.now();

    LearningProgress progress;
    if (existing != null) {
      progress = existing.copyWith(
        lastAccessedAt: now,
        courseTitle: title,
        thumbnailUrl: thumbnailUrl ?? existing.thumbnailUrl,
        totalDurationSec: totalPages ?? existing.totalDurationSec,
        contentType: 'pdf',
        contentRef: pdfId,
      );
    } else {
      progress = LearningProgress(
        courseId: pdfId,
        courseTitle: title,
        thumbnailUrl: thumbnailUrl,
        firstAccessedAt: now,
        lastAccessedAt: now,
        progressPercent: 0.0,
        totalDurationSec: totalPages,
        contentType: 'pdf',
        contentRef: pdfId,
      );
    }

    await saveProgress(progress);

    // Update stats
    final stats = await getStats();
    stats.totalPdfsRead += 1;
    stats.lastActiveAt = now;
    await _saveStats(stats);
  }

  /// Update PDF reading position (page number)
  static Future<void> updatePdfReadPosition(String pdfId, int currentPage, int totalPages) async {
    final existing = await getProgress(pdfId);
    if (existing == null) return; // should not happen, but safeguard

    final now = DateTime.now();
    final progressPercent = totalPages > 0 ? currentPage / totalPages : 0.0;
    final isCompleted = progressPercent >= 0.95;

    var updated = existing.copyWith(
      progressPercent: progressPercent,
      lastPositionSec: currentPage,
      totalDurationSec: totalPages,
      lastAccessedAt: now,
      isCompleted: isCompleted,
    );

    if (isCompleted && !existing.isCompleted) {
      updated = updated.copyWith(completedAt: now);
      // increment completed PDFs
      final stats = await getStats();
      stats.completedPdfs += 1;
      await _saveStats(stats);
    }

    await saveProgress(updated);
  }

  /// Record that a PDF was fully read (manual completion if needed)
  static Future<void> recordPdfComplete(String pdfId) async {
    final progress = await getProgress(pdfId);
    if (progress != null && !progress.isCompleted) {
      await markCompleted(progress);
      final stats = await getStats();
      stats.completedPdfs += 1;
      await _saveStats(stats);
    }
  }
}

/// Learning statistics summary
class LearningStats {
  int totalVideosWatched;
  int completedVideos;
  int totalPdfsRead;
  int completedPdfs;
  int totalWatchTimeMinutes;
  int currentStreakDays;
  DateTime? lastActiveAt;

  LearningStats({
    this.totalVideosWatched = 0,
    this.completedVideos = 0,
    this.totalPdfsRead = 0,
    this.completedPdfs = 0,
    this.totalWatchTimeMinutes = 0,
    this.currentStreakDays = 0,
    this.lastActiveAt,
  });

  int get totalItemsStarted => totalVideosWatched + totalPdfsRead;
  int get totalItemsCompleted => completedVideos + completedPdfs;

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    return LearningStats(
      totalVideosWatched: json['totalVideosWatched'] as int? ?? 0,
      completedVideos: json['completedVideos'] as int? ?? 0,
      totalPdfsRead: json['totalPdfsRead'] as int? ?? 0,
      completedPdfs: json['completedPdfs'] as int? ?? 0,
      totalWatchTimeMinutes: json['totalWatchTimeMinutes'] as int? ?? 0,
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastActiveAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalVideosWatched': totalVideosWatched,
      'completedVideos': completedVideos,
      'totalPdfsRead': totalPdfsRead,
      'completedPdfs': completedPdfs,
      'totalWatchTimeMinutes': totalWatchTimeMinutes,
      'currentStreakDays': currentStreakDays,
      'lastActiveAt': lastActiveAt?.millisecondsSinceEpoch,
    };
  }
}
