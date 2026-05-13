import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../models/video_model.dart';
import 'video_player_screen.dart';
import 'pdf_viewer_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<LearningStats> _statsFuture;
  late Future<List<LearningProgress>> _progressFuture;
  String _filter = 'all'; // 'all', 'videos', 'pdfs'

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _statsFuture = ProgressService.getStats();
      _progressFuture = ProgressService.getAllProgress();
    });
  }

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  Future<void> _openContent(LearningProgress progress) async {
    final context = this.context;
    if (!mounted) return;

    if (progress.contentType == 'video') {
      if (progress.contentRef == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video not available')),
          );
        }
        return;
      }
      final videoItem = VideoItem(
        id: progress.courseId,
        title: progress.courseTitle,
        description: '',
        thumbnailUrl: progress.thumbnailUrl,
        videoId: progress.contentRef!,
        channelName: 'E-Thaksalawa',
        durationSeconds: progress.totalDurationSec,
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            video: videoItem,
            startAtSeconds: progress.lastPositionSec,
          ),
        ),
      );
    } else if (progress.contentType == 'pdf') {
      if (progress.contentRef == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF not available')),
          );
        }
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfUrl: progress.contentRef!,
            title: progress.courseTitle,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Progress'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
                if (value == 'clear') {
                  final dialogContext = context;
                  final snackbarContext = context;
                  final confirm = await showDialog<bool>(
                    context: dialogContext,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Progress?'),
                      content: const Text('This will delete all your learning history. This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  await ProgressService.clearAllProgress();
                  if (!mounted) return;
                  _refreshData();
                  ScaffoldMessenger.of(snackbarContext).showSnackBar(
                    const SnackBar(content: Text('All progress cleared')),
                  );
                }
              },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: FutureBuilder<List<LearningProgress>>(
          future: _progressFuture,
          builder: (context, progressSnapshot) {
            if (progressSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your progress...'),
                  ],
                ),
              );
            }

            final progressList = progressSnapshot.data ?? [];

            return FutureBuilder<LearningStats>(
              future: _statsFuture,
              builder: (context, statsSnapshot) {
                final stats = statsSnapshot.data ?? LearningStats();
                final started = stats.totalVideosWatched + stats.totalPdfsRead;
                final completed = stats.completedVideos + stats.completedPdfs;
                final completionPercent = started > 0 ? completed / started : 0.0;

                // Filter and sort
                var filteredList = progressList.where((p) => p.progressPercent > 0 || p.isCompleted).toList();
                if (_filter == 'videos') {
                  filteredList = filteredList.where((p) => p.contentType == 'video').toList();
                } else if (_filter == 'pdfs') {
                  filteredList = filteredList.where((p) => p.contentType == 'pdf').toList();
                }
                filteredList.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildOverallStatsCard(context, stats, completionPercent, started),
                    const SizedBox(height: 20),
                    // Filter chips
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _filter == 'all',
                          onSelected: (_) => _setFilter('all'),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          selectedColor: theme.colorScheme.primaryContainer,
                        ),
                        FilterChip(
                          label: const Text('Videos'),
                          selected: _filter == 'videos',
                          onSelected: (_) => _setFilter('videos'),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          selectedColor: theme.colorScheme.primaryContainer,
                        ),
                        FilterChip(
                          label: const Text('PDFs'),
                          selected: _filter == 'pdfs',
                          onSelected: (_) => _setFilter('pdfs'),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          selectedColor: theme.colorScheme.primaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // History header
                    Row(
                      children: [
                        Icon(Icons.history, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress list
                    if (filteredList.isEmpty)
                      _buildEmptyState(theme)
                    else
                      ...filteredList.map((p) => _buildProgressCard(context, p, onTap: () => _openContent(p))),
                    const SizedBox(height: 80),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverallStatsCard(BuildContext context, LearningStats stats, double completionPercent, int started) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final completed = stats.totalItemsCompleted;
    final totalVideos = stats.totalVideosWatched;
    final totalPdfs = stats.totalPdfsRead;
    final streak = stats.currentStreakDays;
    final watchTime = stats.totalWatchTimeMinutes;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular progress indicator
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: completionPercent,
                        strokeWidth: 8,
                        backgroundColor: onSurface.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(completionPercent * 100).toInt()}%',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text('Done', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Stats grid
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCompactStat(Icons.play_circle_filled, totalVideos.toString(), 'Videos', theme),
                          _buildCompactStat(Icons.picture_as_pdf, totalPdfs.toString(), 'PDFs', theme),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCompactStat(Icons.check_circle, completed.toString(), 'Completed', theme),
                          _buildCompactStat(Icons.local_fire_department, '${streak}d', 'Streak', theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (watchTime > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 14, color: onSurface.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Text(
                    'Total watch time: $watchTime minutes',
                    style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(IconData icon, String value, String label, ThemeData theme) {
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, LearningProgress progress, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    final progressPercent = progress.progressPercent.clamp(0.0, 1.0);
    final isCompleted = progress.isCompleted;
    final lastWatched = _formatLastWatched(progress.lastAccessedAt);

    // Determine content type icon
    IconData? typeIcon;
    if (progress.contentType == 'video') {
      typeIcon = Icons.play_circle_outline;
    } else if (progress.contentType == 'pdf') {
      typeIcon = Icons.picture_as_pdf;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: progress.thumbnailUrl != null && progress.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            progress.thumbnailUrl!,
                            width: 120,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildThumbnailPlaceholder(theme),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 120,
                                height: 68,
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildThumbnailPlaceholder(theme),
                  ),
                  if (isCompleted)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Progress indicator overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      color: Colors.black26,
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: Colors.transparent,
                        color: isCompleted ? Colors.green : primaryColor,
                        minHeight: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.courseTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          lastWatched,
                          style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar with text
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: onSurface.withValues(alpha: 0.1),
                            color: isCompleted ? Colors.green : primaryColor,
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCompleted ? 'Completed' : '${(progressPercent * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? Colors.green : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Trailing icon for content type
              if (typeIcon != null)
                Icon(typeIcon, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(ThemeData theme) {
    return Container(
      width: 120,
      height: 68,
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 32,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final onSurface = theme.colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No learning history yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start watching videos or reading PDFs to track your progress',
            style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  String _formatLastWatched(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }
}

// Extension to sort list
extension SortExtension<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final list = List<T>.from(this);
    list.sort(compare);
    return list;
  }
}
