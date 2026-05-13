import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/video_model.dart';
import '../services/ethaksalawa_service.dart';
import 'video_player_screen.dart';

class CoursesTabContent extends StatefulWidget {
  const CoursesTabContent({super.key});

  @override
  State<CoursesTabContent> createState() => _CoursesTabContentState();
}

class _CoursesTabContentState extends State<CoursesTabContent> {
  List<CourseItem> _courses = [];
  bool _isLoading = true;
  String? _error;

  // Filter states - null means "All"
  String? _selectedGrade;
  String? _selectedLanguage;
  String? _selectedSubject;

  late final List<String> _availableGrades;
  late final List<String> _availableLanguages;
  late final List<String> _availableSubjects;

  @override
  void initState() {
    super.initState();
    _availableGrades = EthaksalawaService.getAvailableGrades();
    _availableLanguages = EthaksalawaService.getAvailableLanguages();
    _availableSubjects = EthaksalawaService.getAvailableSubjects();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courses = await EthaksalawaService.fetchCourses(
        grade: _selectedGrade,
        language: _selectedLanguage,
        subject: _selectedSubject,
      );

      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _fetchCourses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _buildBody(theme, onSurface, primaryColor),
    );
  }

  Widget _buildBody(ThemeData theme, Color onSurface, Color primaryColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading courses...',
              style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    if (_error != null && _courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading courses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Filters bar
          _buildFiltersBar(theme, onSurface, primaryColor),
          const SizedBox(height: 12),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${_courses.length} course${_courses.length != 1 ? 's' : ''} found',
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Course list
          ..._courses.map((course) => _CourseListItem(
                course: course,
                selectedGrade: _selectedGrade,
                selectedLanguage: _selectedLanguage,
                onTap: () => _onCourseTap(course),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(ThemeData theme, Color onSurface, Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Icon(Icons.tune, size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Filters',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
                  ),
                  const Spacer(),
                  if (_selectedGrade != null || _selectedLanguage != null || _selectedSubject != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedGrade = null;
                          _selectedLanguage = null;
                          _selectedSubject = null;
                        });
                        _fetchCourses();
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Grade chip
                _buildFilterChip(
                  label: 'Grade: ${_selectedGrade?.padLeft(2, '0') ?? 'All'}',
                  onTap: () => _showGradeBottomSheet(theme),
                  isSelected: false,
                  primaryColor: primaryColor,
                  onSurface: onSurface,
                  theme: theme,
                ),
                // Language chip
                _buildFilterChip(
                  label: 'Language: ${_selectedLanguage ?? 'All'}',
                  onTap: () => _showLanguageBottomSheet(theme),
                  isSelected: false,
                  primaryColor: primaryColor,
                  onSurface: onSurface,
                  theme: theme,
                ),
                // Subject chip
                _buildFilterChip(
                  label: 'Subject: ${_selectedSubject ?? 'All'}',
                  onTap: () => _showSubjectBottomSheet(theme),
                  isSelected: false,
                  primaryColor: primaryColor,
                  onSurface: onSurface,
                  theme: theme,
                ),
              ],
            ),
            // Active filters clear
            if (_selectedSubject != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Active: ', style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6))),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSubject = null;
                      });
                      _fetchCourses();
                    },
                    child: Chip(
                      label: Text(_selectedSubject!, style: const TextStyle(fontSize: 11)),
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedSubject = null;
                        });
                        _fetchCourses();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
    required Color primaryColor,
    required Color onSurface,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : onSurface.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_drop_down, size: 16, color: isSelected ? theme.colorScheme.onPrimary : onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? theme.colorScheme.onPrimary : onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGradeBottomSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterBottomSheet(
        title: 'Select Grade',
        items: _availableGrades,
        selected: _selectedGrade,
        onSelected: (value) {
          setState(() {
            _selectedGrade = value;
          });
          _fetchCourses();
        },
        theme: theme,
      ),
    );
  }

  void _showLanguageBottomSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterBottomSheet(
        title: 'Select Language',
        items: _availableLanguages,
        selected: _selectedLanguage,
        onSelected: (value) {
          setState(() {
            _selectedLanguage = value;
          });
          _fetchCourses();
        },
        theme: theme,
      ),
    );
  }

  void _showSubjectBottomSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterBottomSheet(
        title: 'Select Subject',
        items: _availableSubjects,
        selected: _selectedSubject,
        onSelected: (value) {
          setState(() {
            _selectedSubject = value;
          });
          _fetchCourses();
        },
        theme: theme,
      ),
    );
  }

  Widget _buildFilterBottomSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onSelected,
    required ThemeData theme,
  }) {
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: selected == null,
                onSelected: (_) => onSelected(null),
              ),
              ...items.map((item) => FilterChip(
                    label: Text(EthaksalawaService.formatSubject(item)),
                    selected: selected == item,
                    onSelected: (_) => onSelected(item),
                  )),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
   }

  void _onCourseTap(CourseItem course) {
    final url = course.youtubeUrl ?? '';
    final videoId = _extractYouTubeVideoId(url);
    if (videoId != null) {
      final videoItem = VideoItem(
        id: course.id,
        title: course.title,
        description: course.subject != null ? 'Subject: ${course.subject}' : course.description,
        thumbnailUrl: course.thumbnailUrl,
        videoId: videoId,
        channelName: 'E-Thaksalawa',
        durationSeconds: course.duration,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(video: videoItem),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open "${course.title}" - invalid video URL'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _extractYouTubeVideoId(String url) {
    final patterns = [
      RegExp(r'v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]{11})'),
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
}

class _CourseListItem extends StatelessWidget {
  final CourseItem course;
  final String? selectedGrade;
  final String? selectedLanguage;
  final VoidCallback onTap;

  const _CourseListItem({
    required this.course,
    this.selectedGrade,
    this.selectedLanguage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

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
              // Thumbnail with play button overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            course.thumbnailUrl!,
                            width: 160,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildThumbnailPlaceholder(theme),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 160,
                                height: 90,
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
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
                  // Play button overlay
                  SizedBox(
                    width: 160,
                    height: 90,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: theme.colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Title and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.school_outlined, size: 12, color: onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          course.grade ?? selectedGrade ?? 'All',
                          style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                        ),
                        if (course.subject != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.category_outlined, size: 12, color: onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            course.subject!,
                            style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.language_outlined, size: 12, color: onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          course.language ?? selectedLanguage ?? 'All',
                          style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
                        ),
                        if (course.duration != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.access_time_outlined, size: 12, color: onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(course.duration!),
                            style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(ThemeData theme) {
    return Container(
      width: 160,
      height: 90,
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 40,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remMinutes = minutes % 60;
      return '${hours.toString().padLeft(2, '0')}:${remMinutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
