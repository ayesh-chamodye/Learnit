import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/progress_service.dart';
import '../services/api_client.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String? localPath;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.localPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int? _currentPage;
  int? _totalPages;
  bool _isLoading = true;
  String? _error;
  String? _localFile;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  bool _isBookmarked = false;
  bool _hasRecordedStart = false;
  Timer? _progressTimer;

  static final Map<String, String> _downloadedFiles = {};

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveCurrentProgress();
    super.dispose();
  }

  Future<void> _preparePdf() async {
    if (widget.localPath != null) {
      setState(() {
        _localFile = widget.localPath;
        _isLoading = false;
      });
      return;
    }

    if (_downloadedFiles.containsKey(widget.pdfUrl)) {
      setState(() {
        _localFile = _downloadedFiles[widget.pdfUrl];
        _isLoading = false;
      });
      return;
    }

    await _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    // Validate URL upfront
    if (widget.pdfUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Cannot download: PDF URL is empty';
          _isLoading = false;
        });
      }
      return;
    }

    final uri = Uri.tryParse(widget.pdfUrl);
    if (uri == null || !uri.hasAbsolutePath) {
      if (mounted) {
        setState(() {
          _error = 'Invalid PDF URL';
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _error = null;
    });

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Use configured ApiClient for consistent settings
      final dio = ApiClient().dio;

      String dirPath;
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('download_path') ?? '';

      if (savedPath.isNotEmpty) {
        dirPath = savedPath;
      } else {
        if (Platform.isAndroid) {
          final directory = await getExternalStorageDirectory();
          dirPath = directory?.path ?? (await getApplicationDocumentsDirectory()).path;
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            dirPath = downloadsDir.path;
          }
        } else {
          dirPath = (await getApplicationDocumentsDirectory()).path;
        }
      }

      final fileName = _sanitizeFileName(widget.title);
      final filePath = p.join(dirPath, '$fileName.pdf');

      await Directory(dirPath).create(recursive: true);

      await dio.download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      _downloadedFiles[widget.pdfUrl] = filePath;

      if (mounted) {
        setState(() {
          _localFile = filePath;
          _isDownloading = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isDownloading = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _sanitizeFileName(String name) {
    final sanitized = name
        .replaceAll(r'[\\/*?:"<>|]', '_')
        .replaceAll(' ', '_');
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }

  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _saveCurrentProgress();
    });
  }

  void _saveCurrentProgress() {
    if (_totalPages != null && _currentPage != null) {
      ProgressService.updatePdfReadPosition(widget.pdfUrl, _currentPage!, _totalPages!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              setState(() => _isBookmarked = !_isBookmarked);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _localFile != null ? null : _downloadPdf,
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: _buildBody(theme, onSurface, primary),
    );
  }

  Widget _buildBody(ThemeData theme, Color onSurface, Color primary) {
    if (_isLoading || _isDownloading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDownloading) ...[
              CircularProgressIndicator(
                value: _downloadProgress,
                backgroundColor: onSurface.withValues(alpha: 0.3),
                color: primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Downloading... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
              ),
            ] else ...[
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
              const SizedBox(height: 16),
              const Text('Loading PDF...'),
            ],
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
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load PDF',
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
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download),
                label: const Text('Retry Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_localFile == null) {
      return Center(
        child: Text('No PDF available', style: TextStyle(color: onSurface)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PDFView(
            filePath: _localFile,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            onRender: (pages) async {
              if (!mounted) return;
              setState(() {
                _totalPages = pages;
                _isLoading = false;
              });
              if (!_hasRecordedStart) {
                await ProgressService.recordPdfStart(
                  widget.pdfUrl,
                  widget.title,
                  totalPages: pages,
                );
                _hasRecordedStart = true;
              }
              _startProgressTracking();
            },
            onError: (error) {
              setState(() => _error = error.toString());
            },
            onPageError: (page, error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error on page $page: $error')),
                );
              }
            },
            onPageChanged: (int? page, int? total) {
              if (!mounted) return;
              setState(() {
                _currentPage = page;
              });
              _saveCurrentProgress();
            },
          ),
        ),
        Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (_totalPages != null)
                Expanded(
                  child: Text(
                    'Page ${_currentPage ?? 1} of $_totalPages',
                    style: TextStyle(fontWeight: FontWeight.w500, color: onSurface),
                  ),
                ),
              IconButton(
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                onPressed: _isDownloading ? null : _downloadPdf,
                tooltip: 'Download PDF',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
