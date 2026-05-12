import 'package:flutter/material.dart';
import '../models/pdf_model.dart';
import '../services/api_service.dart';
import 'pdf_viewer_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  final String title;
  final IconData icon;
  final Color color;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();

  // Static cache shared across all CategoryScreen instances
  static final Map<String, List<PdfItem>> _categoryCache = {};
  static final Map<String, int> _categoryCurrentPage = {};
  static final Map<String, int> _categoryTotalPages = {};
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<PdfItem> _allItems = []; // All loaded items (unfiltered)
  List<PdfItem> _filteredItems = []; // Items after search filter
  bool _isLoadingFirst = true; // First page loading
  bool _isLoadingMore = false; // Additional pages loading
  bool _isSearching = false; // Search-triggered full load in progress
  String? _error;
  int _currentPage = 0; // Last loaded page number
  int _totalPages = 1; // Total available pages
  bool _hasFetchedFirstPage = false; // Track if page 1 has been fetched
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // Load only first page initially
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // User is searching - need to load all pages
      _isSearching = true;
      _loadAllPagesForSearch();
    } else {
      // Search cleared
      _isSearching = false;
      _applySearch();
    }
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_allItems);
      } else {
        _filteredItems = _allItems.where((item) {
          return item.title.toLowerCase().contains(query) ||
                 (item.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Load more when scrolled to within 200px of bottom
    if (position.pixels >= position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages &&
        !_isSearching) {
      _loadNextPage();
    }
  }

  /// Load only the first page (page 1)
  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoadingFirst = true;
      _error = null;
    });

    try {
      final result = await ApiService.fetchPdfsByCategory(widget.category, page: 1);

      // Preload images for smooth scrolling
      _preloadImages(result.items);

      setState(() {
        _allItems = List.from(result.items);
        _currentPage = result.currentPage;
        _totalPages = result.totalPages;
        _isLoadingFirst = false;
        _hasFetchedFirstPage = true;
        _applySearch();
        // Update cache
        CategoryScreen._categoryCache[widget.category] = List.from(_allItems);
        CategoryScreen._categoryCurrentPage[widget.category] = _currentPage;
        CategoryScreen._categoryTotalPages[widget.category] = _totalPages;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingFirst = false;
      });
    }
  }

  /// Load next page (triggered by scroll)
  Future<void> _loadNextPage() async {
    final nextPage = _currentPage + 1;
    if (nextPage > _totalPages) return;

    setState(() {
      _isLoadingMore = true;
      _error = null;
    });

    try {
      final result = await ApiService.fetchPdfsByCategory(widget.category, page: nextPage);

      // Avoid duplicates
      final existingIds = _allItems.map((e) => e.id).toSet();
      final newItems = result.items.where((item) => !existingIds.contains(item.id)).toList();

      // Preload images
      _preloadImages(newItems);

      setState(() {
        _allItems.addAll(newItems);
        _currentPage = result.currentPage;
        _totalPages = result.totalPages;
        _isLoadingMore = false;
        _applySearch();
        // Update cache
        CategoryScreen._categoryCache[widget.category] = List.from(_allItems);
        CategoryScreen._categoryCurrentPage[widget.category] = _currentPage;
        CategoryScreen._categoryTotalPages[widget.category] = _totalPages;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  /// Load all remaining pages sequentially (used when search is active)
  Future<void> _loadAllPagesForSearch() async {
    // Ensure first page is loaded to know totalPages
    if (!_hasFetchedFirstPage) {
      await _loadFirstPage();
      // If error occurred, _loadFirstPage sets _error and returns
      if (_error != null) {
        _isSearching = false;
        return;
      }
    }

    // Load pages one by one starting from current page + 1
    int pageToLoad = _currentPage + 1;
    while (pageToLoad <= _totalPages && mounted) {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });

      try {
        final result = await ApiService.fetchPdfsByCategory(widget.category, page: pageToLoad);

        // Avoid duplicates
        final existingIds = _allItems.map((e) => e.id).toSet();
        final newItems = result.items.where((item) => !existingIds.contains(item.id)).toList();

        // Preload images
        _preloadImages(newItems);

        setState(() {
          _allItems.addAll(newItems);
          _currentPage = result.currentPage;
          _totalPages = result.totalPages;
          _isLoadingMore = false;
        });

        pageToLoad++;
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoadingMore = false;
        });
        break;
      }
    }

    if (mounted) {
      setState(() {
        _isSearching = false;
      });
      _applySearch();
    }
  }

  Future<void> _refresh() async {
    // Clear cache and reload first page
    _hasFetchedFirstPage = false;
    CategoryScreen._categoryCache.remove(widget.category);
    CategoryScreen._categoryCurrentPage.remove(widget.category);
    CategoryScreen._categoryTotalPages.remove(widget.category);
    _allItems.clear();
    _filteredItems.clear();
    _currentPage = 0;
    _totalPages = 1;
    await _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search in ${widget.title}...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (_isLoadingMore && !_isSearching)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Show searching overlay when loading all pages for search
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(widget.color)),
            const SizedBox(height: 16),
            Text('Searching all pages...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_isLoadingFirst) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(widget.color)),
            const SizedBox(height: 16),
            Text('Loading ${widget.title}...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_error != null && _allItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading ${widget.title}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No results for "${_searchController.text}"'
                  : 'No ${widget.title} available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length + (_isLoadingMore && !_isSearching ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredItems.length) {
            // Loading more indicator at bottom
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(widget.color)),
                    const SizedBox(height: 8),
                    Text(
                      'Loading more...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }
          final pdf = _filteredItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _CategoryPdfCard(
              pdf: pdf,
              color: widget.color,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(pdfUrl: pdf.pdfUrl ?? '', title: pdf.title),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryPdfCard extends StatelessWidget {
  final PdfItem pdf;
  final Color color;
  final VoidCallback onTap;

  const _CategoryPdfCard({required this.pdf, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
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
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: pdf.thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: pdf.thumbnailUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: color.withValues(alpha: 0.08),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildPdfIcon(color),
                        ),
                      )
                    : _buildPdfIcon(color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pdf.description != null && pdf.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        pdf.description!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.menu_book, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          pdf.pageCount != null ? '${pdf.pageCount} pages' : 'PDF',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        if (pdf.category != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.category, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            pdf.category!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  Widget _buildPdfIcon(Color color) {
    return Center(
      child: Icon(Icons.picture_as_pdf, size: 28, color: color),
    );
  }
}

// Preload images helper
void _preloadImages(List<PdfItem> items) {
  for (final pdf in items) {
    if (pdf.thumbnailUrl != null) {
      CachedNetworkImageProvider(pdf.thumbnailUrl!).resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool sync) {}),
      );
    }
  }
}
