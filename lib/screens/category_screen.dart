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
}

class _CategoryScreenState extends State<CategoryScreen> {
   List<PdfItem> _allItems = []; // All loaded items (unfiltered)
   List<PdfItem> _filteredItems = []; // Items after search filter
   bool _isLoadingFirst = true; // Initial page load
   bool _isLoadingMore = false; // Loading subsequent pages
   String? _error;
   int _currentPage = 0; // Last loaded page number
   int _totalPages = 1; // Total available pages
   bool _isSearchLoadingChain = false; // Tracks if a search-triggered loading chain is active
   final TextEditingController _searchController = TextEditingController();
   final ScrollController _scrollController = ScrollController();

  // Static cache shared across all CategoryScreen instances
  static final Map<String, List<PdfItem>> _categoryCache = {};
  static final Map<String, int> _categoryCurrentPage = {};
  static final Map<String, int> _categoryTotalPages = {};

  @override
  void initState() {
    super.initState();
    _restoreFromCache();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // If not in cache or cache not fully loaded, load next pages as needed
    if (_currentPage < _totalPages) {
      _loadNextPage();
    }
  }

  void _restoreFromCache() {
    if (_categoryCache.containsKey(widget.category)) {
      setState(() {
        _allItems = List.from(_categoryCache[widget.category]!);
        _currentPage = _categoryCurrentPage[widget.category] ?? 0;
        _totalPages = _categoryTotalPages[widget.category] ?? 1;
        _isLoadingFirst = false;
        _applySearch();
      });
    } else {
      // Start fresh
      _isLoadingFirst = true;
    }
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
    _applySearch();
    final query = _searchController.text.trim();
    // If search query is non-empty and there are more pages to load, and no load in progress, start loading chain
    if (query.isNotEmpty && _currentPage < _totalPages && !_isLoadingFirst && !_isLoadingMore && !_isSearchLoadingChain) {
      _isSearchLoadingChain = true;
      _loadNextPage();
    }
  }

  void _applySearch() {
    // If search is cleared, reset the search loading chain flag
    if (_searchController.text.trim().isEmpty) {
      _isSearchLoadingChain = false;
    }
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
        _currentPage < _totalPages) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    final nextPage = _currentPage + 1;
    setState(() {
      if (nextPage == 1) {
        _isLoadingFirst = true;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });

    try {
      final result = await ApiService.fetchPdfsByCategory(widget.category, page: nextPage);

      // Avoid duplicates: check existing IDs
      final existingIds = _allItems.map((e) => e.id).toSet();
      final newItems = result.items.where((item) => !existingIds.contains(item.id)).toList();

      // Preload images for smooth scrolling
      _preloadImages(newItems);

      setState(() {
        _allItems.addAll(newItems);
        _currentPage = result.currentPage;
        _totalPages = result.totalPages;
        _isLoadingFirst = false;
        _isLoadingMore = false;
        _applySearch();
        // Update cache
        _categoryCache[widget.category] = List.from(_allItems);
        _categoryCurrentPage[widget.category] = _currentPage;
        _categoryTotalPages[widget.category] = _totalPages;
      });
      
      // Auto-continue loading if search is active and more pages remain
      if (mounted && _searchController.text.trim().isNotEmpty && _currentPage < _totalPages) {
        if (!_isLoadingMore && !_isLoadingFirst) {
          // Mark chain active if not already
          if (!_isSearchLoadingChain) {
            _isSearchLoadingChain = true;
          }
          await Future.delayed(const Duration(milliseconds: 100)); // Small delay to yield UI
          _loadNextPage();
          return; // Skip flag clearing; the recursive call will handle it
        }
      }
      // Chain ends here (no more pages or search cleared)
      if (_isSearchLoadingChain) {
        _isSearchLoadingChain = false;
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        if (nextPage == 1) {
          _isLoadingFirst = false;
        } else {
          _isLoadingMore = false;
        }
      });
      // Clear search loading chain flag on error
      if (_isSearchLoadingChain) {
        _isSearchLoadingChain = false;
      }
    }
  }

  Future<void> _refresh() async {
    // Cancel any ongoing search loading chain
    _isSearchLoadingChain = false;
    _categoryCache.remove(widget.category);
    _categoryCurrentPage.remove(widget.category);
    _categoryTotalPages.remove(widget.category);
    _allItems.clear();
    _filteredItems.clear();
    _currentPage = 0;
    _totalPages = 1;
    await _loadNextPage();
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
          if (_isLoadingMore && _searchController.text.isNotEmpty)
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
        itemCount: _filteredItems.length + (_isLoadingMore ? 1 : 0),
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
                       _searchController.text.isNotEmpty ? 'Searching all results...' : 'Loading more...',
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

// Preload images helper - call when new items are added
void _preloadImages(List<PdfItem> items) {
  for (final pdf in items) {
    if (pdf.thumbnailUrl != null) {
      // Trigger cache download
      CachedNetworkImageProvider(pdf.thumbnailUrl!).resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool sync) {}),
      );
    }
  }
}
