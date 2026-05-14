import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/video_model.dart';
import '../services/ethaksalawa_service.dart';
import '../services/api_service.dart';
import '../widgets/course_card.dart';
import 'video_player_screen.dart';

class CourseCategoryScreen extends StatefulWidget {
  final String grade;
  final String? initialLanguage;

  const CourseCategoryScreen({
    super.key,
    required this.grade,
    this.initialLanguage,
  });

  @override
  State<CourseCategoryScreen> createState() => _CourseCategoryScreenState();
}

class _CourseCategoryScreenState extends State<CourseCategoryScreen> {
  List<CourseItem> _courses = [];
  bool _isLoadingFirst = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 1;
  final ScrollController _scrollController = ScrollController();
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage ?? 'English';
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<PaginatedResult<CourseItem>> _fetchPage(int page) async {
    return await EthaksalawaService.fetchCourses(
      grade: widget.grade,
      language: _selectedLanguage,
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

  Map<String, List<CourseItem>> get _groupedBySubject {
    final map = <String, List<CourseItem>>{};
    for (final course in _courses) {
      final subject = course.subject ?? 'Other';
      (map[subject] ??= []).add(course);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Grade ${int.parse(widget.grade)} - $_selectedLanguage'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'E-Thaksalawa',
                applicationVersion: '1.0',
                children: const [
                  Text('Educational video resources from Sri Lanka\'s e-learning platform'),
                ],
              );
            },
          ),
        ],
      ),
      body: _buildBody(theme, onSurface),
    );
  }

  Widget _buildBody(ThemeData theme, Color onSurface) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        children: [
          _buildLanguageSelector(theme, onSurface),
          const SizedBox(height: 16),
          if (_isLoadingFirst && _courses.isEmpty)
            _buildLoadingView(onSurface)
          else if (_error != null && _courses.isEmpty)
            _buildErrorView(onSurface, theme)
          else if (_courses.isEmpty)
            _buildEmptyView(onSurface)
          else
            ..._buildContent(theme, onSurface),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLoadingView(Color onSurface) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Loading courses...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorView(Color onSurface, ThemeData theme) {
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
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
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
          Icon(Icons.menu_book_outlined, size: 80, color: onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No courses found',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different language',
            style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(ThemeData theme, Color onSurface) {
    final grouped = _groupedBySubject;
    final subjects = grouped.keys.toList()..sort();

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
    ];

    for (final subject in subjects) {
      widgets.add(_buildSubjectSection(theme, subject, grouped[subject]!));
    }

    if (_isLoadingMore) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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

  Widget _buildLanguageSelector(ThemeData theme, Color onSurface) {
    return FutureBuilder<List<String>>(
      future: EthaksalawaService.getAvailableLanguages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 44,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final languages = snapshot.data!;
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: languages.map((lang) {
              final isSelected = lang == _selectedLanguage;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    if (isSelected) return;
                    setState(() {
                      _selectedLanguage = lang;
                    });
                    _loadFirstPage();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : onSurface.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      lang,
                      style: TextStyle(
                        color: isSelected ? theme.colorScheme.onPrimary : onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSubjectSection(ThemeData theme, String subject, List<CourseItem> courses) {
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.primary,
                width: 4,
              ),
            ),
          ),
          child: Text(
            EthaksalawaService.formatSubject(subject),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final course = courses[index];
            return CourseCard(
              key: ValueKey(course.id),
              course: course,
              grade: widget.grade,
              onSurface: onSurface,
              primaryColor: theme.colorScheme.primary,
              onTap: () => _onCourseTap(course),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
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
}
