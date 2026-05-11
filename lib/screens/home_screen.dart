import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as f;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pdf_model.dart';
import '../services/api_service.dart';
import 'category_screen.dart';
import 'pdf_viewer_screen.dart';
import 'courses_screen.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
  int _currentIndex = 0;
  Map<String, List<PdfItem>> _categoryPdfs = {};
  bool _isLoading = true;
  String? _error;

  final List<String> _categories = [
    'past-papers',
    'model-papers',
    'teacher-guides',
    'term-test-papers',
    'text-books',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllCategories();
  }

  Future<void> _fetchAllCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, List<PdfItem>> results = {};
      
      for (final category in _categories) {
        try {
          f.debugPrint('Fetching: $category');
          final response = await ApiService.fetchPdfsByCategory(category);
          f.debugPrint('Got ${response.items.length} for $category (page ${response.currentPage}/${response.totalPages})');
          results[category] = response.items;
        } catch (e) {
          f.debugPrint('ERROR $category: $e');
          results[category] = [];
        }
      }

      setState(() {
        _categoryPdfs = results;
        _isLoading = false;
      });
    } catch (e) {
      f.debugPrint('FATAL: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    String getAppBarTitle() {
      switch (_currentIndex) {
        case 0: return 'LearnIt';
        case 1: return 'Courses';
        case 2: return 'Quizzes';
        case 3: return 'Progress';
        default: return 'LearnIt';
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Quizzes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildCoursesTab();
      case 2:
        return _buildQuizzesTab();
      case 3:
        return _buildProgressTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading categories...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchAllCategories,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllCategories,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore learning resources',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ..._categories.map((category) {
            final items = _categoryPdfs[category] ?? [];
            final categoryName = _categoryLabels[category] ?? category;
            final icon = _categoryIcons[category] ?? Icons.folder;
            final color = _categoryColors[category] ?? Colors.grey;

            return _CategorySection(
              title: categoryName,
              icon: icon,
              color: color,
              items: items,
              onViewAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(
                      category: category,
                      title: categoryName,
                      icon: icon,
                      color: color,
                    ),
                  ),
                );
              },
              onCardTap: (pdf) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      pdfUrl: pdf.pdfUrl ?? '',
                      title: pdf.title,
                    ),
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  static const Map<String, String> _categoryLabels = {
    'past-papers': 'Past Papers',
    'model-papers': 'Model Papers',
    'teacher-guides': 'Teacher Guides',
    'term-test-papers': 'Term Tests',
    'text-books': 'Text Books',
  };

  static const Map<String, IconData> _categoryIcons = {
    'past-papers': Icons.description_outlined,
    'model-papers': Icons.assignment,
    'teacher-guides': Icons.menu_book,
    'term-test-papers': Icons.edit_note,
    'text-books': Icons.book,
  };

  static const Map<String, Color> _categoryColors = {
    'past-papers': Colors.blue,
    'model-papers': Colors.green,
    'teacher-guides': Colors.purple,
    'term-test-papers': Colors.orange,
    'text-books': Colors.teal,
   };

   Widget _buildCoursesTab() {
     return const CoursesTabContent();
   }

   Widget _buildQuizzesTab() => _buildEmptyTab(Icons.quiz, 'Quizzes', 'Test your knowledge');
   Widget _buildProgressTab() => _buildEmptyTab(Icons.bar_chart, 'Progress', 'Track your learning milestones');

  Widget _buildEmptyTab(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<PdfItem> items;
  final VoidCallback onViewAll;
  final ValueChanged<PdfItem>? onCardTap;

  const _CategorySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.onViewAll,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    key: ValueKey('category_title_$title'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Text(
                'No $title available',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
               itemBuilder: (context, index) {
                 final pdf = items[index];
                 return Container(
                   width: 140,
                   margin: const EdgeInsets.only(right: 12),
                   child: _PdfCard(
                     pdf: pdf,
                     color: color,
                     onTap: onCardTap != null
                         ? () => onCardTap!(pdf)
                         : () {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text('Opening: ${pdf.title}'),
                                 backgroundColor: Theme.of(context).colorScheme.primary,
                               ),
                             );
                           },
                   ),
                 );
               },
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PdfCard extends StatelessWidget {
  final PdfItem pdf;
  final Color color;
  final VoidCallback onTap;

  const _PdfCard({
    required this.pdf,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                 child: pdf.thumbnailUrl != null
                     ? ClipRRect(
                         borderRadius: const BorderRadius.only(
                           topLeft: Radius.circular(16),
                           topRight: Radius.circular(16),
                         ),
                         child: CachedNetworkImage(
                           imageUrl: pdf.thumbnailUrl!,
                           width: double.infinity,
                           height: double.infinity,
                           fit: BoxFit.cover,
                           placeholder: (context, url) => Container(
                             color: color.withValues(alpha: 0.08),
                             child: Center(
                               child: SizedBox(
                                 width: 24,
                                 height: 24,
                                 child: CircularProgressIndicator(
                                   strokeWidth: 2,
                                   valueColor: AlwaysStoppedAnimation<Color>(color),
                                 ),
                               ),
                             ),
                           ),
                           errorWidget: (context, url, error) => _buildPdfIcon(context, color),
                         ),
                       )
                     : _buildPdfIcon(context, color),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.menu_book, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          pdf.pageCount != null ? '${pdf.pageCount} p' : 'PDF',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfIcon(BuildContext context, Color color) {
    return Center(
      child: Icon(Icons.picture_as_pdf, size: 40, color: color),
    );
  }
}
