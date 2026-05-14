import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/video_model.dart';
import '../services/ethaksalawa_service.dart';
import '../services/api_service.dart';
import 'video_player_screen.dart';

class CoursesTabContent extends StatefulWidget {
  const CoursesTabContent({super.key});

  @override
  State<CoursesTabContent> createState() => _CoursesTabContentState();
}

class _CoursesTabContentState extends State<CoursesTabContent> {
  // Pagination state
  List<CourseItem> _courses = [];
  bool _isLoadingFirst = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 1;
  final ScrollController _scrollController = ScrollController();

  // Filter states
  String? _selectedGrade;
  String? _selectedLanguage;
  String? _selectedSubject;

  List<String> _availableGrades = [];
  List<String> _availableLanguages = [];
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFilters().then((_) => _loadFirstPage());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      // Grades 01-13 as zero-padded strings (API format)
      final grades = List.generate(13, (i) => (i + 1).toString().padLeft(2, '0'));
      // Languages in order
      final languages = ['Sinhala', 'English', 'Tamil'];
      
      if (mounted) {
        setState(() {
          _availableGrades = grades;
          _availableLanguages = languages;
          // Set defaults: Grade 01, Sinhala
          _selectedGrade = '01';
          _selectedLanguage = 'Sinhala';
        });
      }
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<PaginatedResult<CourseItem>> _fetchPage(int page) async {
    return await EthaksalawaService.fetchCourses(
      grade: _selectedGrade,
      language: _selectedLanguage,
      subject: _selectedSubject,
      page: page,
    );
  }

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFirst = true;
      _error = null;
    });
    try {
      final result = await _fetchPage(1);
      if (!mounted) return;
      setState(() {
        _courses = result.items;
        _currentPage = result.currentPage;
        _totalPages = result.totalPages;
        // Extract unique subjects from the loaded courses
        _availableSubjects = result.items
            .map((c) => c.subject)
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();
        _isLoadingFirst = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingFirst = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
      _error = null;
    });
    try {
      final result = await _fetchPage(_currentPage + 1);
      if (!mounted) return;
      setState(() {
        final existingIds = _courses.map((c) => c.id).toSet();
        final newItems = result.items.where((item) => !existingIds.contains(item.id)).toList();
        _courses.addAll(newItems);
        _currentPage = result.currentPage;
        _totalPages = result.totalPages;
        _isLoadingMore = false;
        // Update subjects from combined list
        _availableSubjects = _courses
            .map((c) => c.subject)
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    if (_isLoadingFirst) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadNextPage();
    }
  }

  Future<void> _refresh() async {
    await _loadFirstPage();
  }

  void _onCourseTap(CourseItem course) {
    final url = course.youtubeUrl;
    if (url != null) {
      final videoId = _extractYouTubeVideoId(url);
      if (videoId == null) {
        _showUnsupportedContentSnackBar(course);
        return;
      }
      final videoItem = VideoItem(
        id: course.id,
        title: course.title,
        description: course.description,
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
      _showUnsupportedContentSnackBar(course);
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

  void _showUnsupportedContentSnackBar(CourseItem course) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot open "${course.title}" - unsupported content type'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        children: [
          _buildFiltersBar(theme, onSurface, primaryColor),
          const SizedBox(height: 12),
          if (_isLoadingFirst && _courses.isEmpty)
            _buildLoadingView(onSurface, primaryColor)
          else if (_error != null && _courses.isEmpty)
            _buildErrorView(onSurface, primaryColor, theme)
          else if (_courses.isEmpty)
            _buildEmptyView(onSurface)
          else
            ..._buildCourseList(theme, onSurface, primaryColor),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLoadingView(Color onSurface, Color primaryColor) {
    return Container(
      height: 300,
      alignment: Alignment.center,
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

  Widget _buildErrorView(Color onSurface, Color primaryColor, ThemeData theme) {
    return Container(
      height: 300,
      alignment: Alignment.center,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
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

  Widget _buildEmptyView(Color onSurface) {
    return Container(
      height: 300,
      alignment: Alignment.center,
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

  List<Widget> _buildCourseList(ThemeData theme, Color onSurface, Color primaryColor) {
    final widgets = <Widget>[
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
      ..._courses.map((course) => _CourseListItem(
            course: course,
            selectedGrade: _selectedGrade,
            selectedLanguage: _selectedLanguage,
            onTap: () => _onCourseTap(course),
          )),
    ];

    // Show loading more indicator
    if (_isLoadingMore) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading more...',
                  style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show end of list indicator
    if (!_isLoadingMore && _currentPage >= _totalPages && _courses.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'You\'ve reached the end',
              style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ),
      );
    }

    return widgets;
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
                        _availableSubjects = [];
                      });
                      _loadFirstPage();
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
            
            // Language and Grade dropdowns in a row
            Row(
              children: [
                // Language Dropdown
                Expanded(
                  child: _buildDropdown(
                    label: 'Language',
                    value: _selectedLanguage,
                    items: _availableLanguages,
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value;
                        _availableSubjects = []; // Clear subjects when language changes
                      });
                      _loadFirstPage();
                    },
                    theme: theme,
                    onSurface: onSurface,
                    primaryColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Grade Dropdown
                Expanded(
                  child: _buildDropdown(
                    label: 'Grade',
                    value: _selectedGrade,
                    items: _availableGrades,
                    onChanged: (value) {
                      setState(() {
                        _selectedGrade = value;
                        _availableSubjects = []; // Clear subjects when grade changes
                      });
                      _loadFirstPage();
                    },
                    theme: theme,
                    onSurface: onSurface,
                    primaryColor: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Subject filter as horizontal scrollable chips
            if (_availableSubjects.isNotEmpty) ...[
              Text(
                'Subject',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    FilterChip(
                      label: const Text('All Subjects'),
                      selected: _selectedSubject == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSubject = null;
                        });
                        _loadFirstPage();
                      },
                      backgroundColor: onSurface.withValues(alpha: 0.05),
                      selectedColor: primaryColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: _selectedSubject == null ? primaryColor : onSurface,
                      ),
                    ),
                    ..._availableSubjects.map((subject) => FilterChip(
                          label: Text(subject),
                          selected: _selectedSubject == subject,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSubject = selected ? subject : null;
                            });
                            _loadFirstPage();
                          },
                          backgroundColor: onSurface.withValues(alpha: 0.05),
                          selectedColor: primaryColor.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: _selectedSubject == subject ? primaryColor : onSurface,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
    required Color onSurface,
    required Color primaryColor,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: onSurface.withValues(alpha: 0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text('Select $label', style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 13)),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('All $label', style: const TextStyle(fontSize: 13)),
            ),
            ...items.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: onChanged,
          style: TextStyle(color: onSurface, fontSize: 13),
          icon: Icon(Icons.arrow_drop_down, color: onSurface.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class _CourseListItem extends StatelessWidget {
  final CourseItem course;
  final String? selectedGrade;
  final String? selectedLanguage;
  final VoidCallback onTap;

  const _CourseListItem({
    required this.course,
    required this.selectedGrade,
    required this.selectedLanguage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: onSurface.withValues(alpha: 0.05),
            image: course.thumbnailUrl != null
                ? DecorationImage(
                    image: NetworkImage(course.thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: course.thumbnailUrl == null
              ? Icon(Icons.play_circle_outline, size: 30, color: theme.colorScheme.primary)
              : null,
        ),
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (course.grade != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Gr ${course.grade}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (course.language != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    course.language!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
