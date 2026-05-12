import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

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

  static final Map<String, String> _downloadedFiles = {};

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    if (widget.localPath != null) {
      setState(() {
        _localFile = widget.localPath;
        _isLoading = false;
      });
      return;
    }

    // Check if already downloaded
    if (_downloadedFiles.containsKey(widget.pdfUrl)) {
      setState(() {
        _localFile = _downloadedFiles[widget.pdfUrl];
        _isLoading = false;
      });
      return;
    }

    // Download the PDF
    await _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _error = null;
    });

    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      final dio = Dio();
      String dirPath;

      // Get download path from settings or use default
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('download_path') ?? '';

      if (savedPath.isNotEmpty) {
        dirPath = savedPath;
      } else {
        // Use default downloads directory
        if (Platform.isAndroid) {
          final directory = await getExternalStorageDirectory();
          dirPath = directory?.path ?? (await getApplicationDocumentsDirectory()).path;
          // Try to use Downloads folder
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

      // Ensure directory exists
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isDownloading = false;
          _isLoading = false;
        });
       }
     }
   }

  String _sanitizeFileName(String name) {
    final sanitized = name
        .replaceAll(r'[\\/*?:"<>|]', '_')
        .replaceAll(' ', '_');
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isDownloading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDownloading) ...[
              CircularProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.grey[300],
                color: Colors.blue[900],
              ),
              const SizedBox(height: 16),
              Text(
                'Downloading... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ] else ...[
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[900]!),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
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
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download),
                label: const Text('Retry Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_localFile == null) {
      return const Center(child: Text('No PDF available'));
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
            onRender: (pages) {
              setState(() {
                _totalPages = pages;
                _isLoading = false;
              });
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
            onViewCreated: (PDFViewController pdfViewController) {},
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page;
              });
            },
          ),
        ),
        // Page indicator and download button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (_totalPages != null)
                Expanded(
                  child: Text(
                    'Page ${_currentPage ?? 1} of $_totalPages',
                    style: const TextStyle(fontWeight: FontWeight.w500),
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
