import 'package:flutter/material.dart';
import '../models/pdf_model.dart';
import '../services/api_service.dart';
import 'pdf_viewer_screen.dart';


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
  List<PdfItem> _allItems = [];
  List<PdfItem> _filteredItems = [];
  bool _isLoadingFirst = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 1;
  bool _hasFetchedFirstPage = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
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
      _isSearching = true;
      _loadAllPagesForSearch();
    } else {
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
    if (position.pixels >= position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages &&
        !_isSearching) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoadingFirst = true;
      _error = null;
    });

    try {
      final result = await ApiService.fetchPdfsByCategory(widget.category, page: 1);


       setState(() {
         _allItems = List.from(result.items);
         _currentPage = result.currentPage;
         _totalPages = result.totalPages;
         _isLoadingFirst = false;
         _hasFetchedFirstPage = true;
         _applySearch();
       });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingFirst = false;
      });
    }
  }

   Future<void> _loadNextPage() async {
     final nextPage = _currentPage + 1;
     if (nextPage > _totalPages) return;

     setState(() {
       _isLoadingMore = true;
       _error = null;
     });

     try {
       final result = await ApiService.fetchPdfsByCategory(widget.category, page: nextPage);
       final existingIds = _allItems.map((e) => e.id).toSet();
       final newItems = result.items.where((item) => !existingIds.contains(item.id)).toList();

       setState(() {
         _allItems.addAll(newItems);
         _currentPage = result.currentPage;
         _totalPages = result.totalPages;
         _isLoadingMore = false;
         _applySearch();
       });
     } catch (e) {
       setState(() {
         _error = e.toString();
         _isLoadingMore = false;
       });
     }
   }

  Future<void> _loadAllPagesForSearch() async {
    if (!_hasFetchedFirstPage) {
      await _loadFirstPage();
      if (_error != null) {
        _isSearching = false;
        return;
      }
    }

    int pageToLoad = _currentPage + 1;
    while (pageToLoad <= _totalPages && mounted) {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });

      try {
        final result = await ApiService.fetchPdfsByCategory(widget.category, page: pageToLoad);
        final existingIds = _allItems.map((e) => e.id).toSet();
        final newItems = result.items.where((item) => !existingIds.contains(item.id)).toList();

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
    _hasFetchedFirstPage = false;
    _allItems.clear();
    _filteredItems.clear();
    _currentPage = 0;
    _totalPages = 1;
    await _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
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
            child: _buildBody(theme, onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, Color onSurface) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(widget.color)),
            const SizedBox(height: 16),
            Text('Searching all pages...', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
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
            Text('Loading ${widget.title}...', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
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
              Text('Error loading ${widget.title}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.8))),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
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
            Icon(Icons.search_off, size: 64, color: onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No results for "${_searchController.text}"'
                  : 'No ${widget.title} available',
              style: TextStyle(fontSize: 16, color: onSurface.withValues(alpha: 0.6)),
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
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(widget.color)),
                    const SizedBox(height: 8),
                    Text(
                      'Loading more...',
                      style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
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
                 if (pdf.pdfUrl == null || pdf.pdfUrl!.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('PDF not available')),
                   );
                   return;
                 }
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => PdfViewerScreen(pdfUrl: pdf.pdfUrl!, title: pdf.title),
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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

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
                        child: Image.network(
                          pdf.thumbnailUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
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
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => _buildPdfIcon(color),
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pdf.description != null && pdf.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        pdf.description!,
                        style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.6)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.menu_book, size: 12, color: onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          pdf.pageCount != null ? '${pdf.pageCount} pages' : 'PDF',
                          style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
                        ),
                        if (pdf.category != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.category, size: 12, color: onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            pdf.category!,
                            style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
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


