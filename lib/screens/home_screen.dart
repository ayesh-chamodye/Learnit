import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'courses_screen.dart';
import 'settings_screen.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
   int _currentIndex = 0;

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
    // No preloading - each category fetches on demand
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icon.png',
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.menu_book,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'LearnIt',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
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
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
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
        return _buildProgressTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildHomeTab();
    }
  }

   Widget _buildHomeTab() {
     return RefreshIndicator(
       onRefresh: () async {},
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
           // Category cards grid
           GridView.builder(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: 2,
               crossAxisSpacing: 16,
               mainAxisSpacing: 16,
               childAspectRatio: 1.0,
             ),
             itemCount: _categories.length,
             itemBuilder: (context, index) {
               final category = _categories[index];
               final categoryName = _categoryLabels[category] ?? category;
               final icon = _categoryIcons[category] ?? Icons.folder;
               final color = _categoryColors[category] ?? Colors.grey;

               return _CategoryCard(
                 title: categoryName,
                 icon: icon,
                 color: color,
                 onTap: () {
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
               );
             },
           ),
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

    Widget _buildProgressTab() => _buildEmptyTab(Icons.bar_chart, 'Progress', 'Track your learning milestones');
    Widget _buildSettingsTab() => const SettingsScreen();

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

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.9),
                color.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
