import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import '../services/progress_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;
  final int? startAtSeconds;

  const VideoPlayerScreen({super.key, required this.video, this.startAtSeconds});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _showControls = false;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    // Record video started
    ProgressService.recordVideoStart(
      widget.video.id,
      widget.video.title,
      widget.video.thumbnailUrl,
      widget.video.durationSeconds,
      widget.video.videoId,
    );

    // Force landscape orientation and hide system UI for fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        forceHD: true,
        enableCaption: true,
      ),
    );

    // Start progress saving timer (every 10 seconds)
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _controller.value.isReady) {
        _saveCurrentProgress();
      }
    });

    // Hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Save final progress
    _progressTimer?.cancel();
    _saveCurrentProgress();

    // Restore portrait orientation and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    // Auto-hide after delay if showing
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _seekBackward() {
    final current = _controller.value.position;
    _controller.seekTo(current - const Duration(seconds: 10));
  }

  void _seekForward() {
    final current = _controller.value.position;
    _controller.seekTo(current + const Duration(seconds: 10));
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  /// Save current watch position to progress service
  void _saveCurrentProgress() {
    final position = _controller.value.position;
    final duration = _controller.metadata.duration;

    if (duration != null && duration.inSeconds > 0) {
      ProgressService.updateWatchPosition(
        widget.video.id,
        position.inSeconds,
        duration.inSeconds,
      );
      debugPrint('Progress saved: ${position.inSeconds}/${duration.inSeconds}s');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Fullscreen YouTube Player
            Center(
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
                onReady: () {
                  if (widget.startAtSeconds != null && widget.startAtSeconds! > 0) {
                    _controller.seekTo(Duration(seconds: widget.startAtSeconds!));
                  }
                  _controller.play();
                },
                onEnded: (data) async {
                  // Capture context before async operations
                  final navigatorContext = context;
                  // Mark as completed
                  await ProgressService.recordVideoComplete(widget.video.id);
                  _saveCurrentProgress();

                  if (!mounted) return;

                  showDialog(
                    context: navigatorContext,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Video Completed!', style: TextStyle(color: Colors.white)),
                      content: const Text('Great job! Would you like to replay?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            _controller.pause();
                            Navigator.pop(context);
                            Navigator.pop(navigatorContext);
                          },
                          child: const Text('Done'),
                        ),
                        TextButton(
                          onPressed: () {
                            _controller.seekTo(const Duration(seconds: 0));
                            _controller.play();
                            Navigator.pop(context);
                          },
                          child: const Text('Replay'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Top bar (back + title) - only visible when controls shown
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Bottom controls - only visible when controls shown
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                            onPressed: _seekBackward,
                            tooltip: 'Rewind 10s',
                          ),
                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                            onPressed: _seekForward,
                            tooltip: 'Forward 10s',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PopupMenuButton<double>(
                            icon: const Icon(Icons.speed, color: Colors.white, size: 20),
                            onSelected: (speed) {
                              _controller.setPlaybackRate(speed);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 0.5, child: Text('0.5x')),
                              PopupMenuItem(value: 1.0, child: Text('Normal')),
                              PopupMenuItem(value: 1.25, child: Text('1.25x')),
                              PopupMenuItem(value: 1.5, child: Text('1.5x')),
                              PopupMenuItem(value: 2.0, child: Text('2x')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            // Persistent back button (always visible, on top)
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                color: Colors.black.withValues(alpha: 0.5),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
              ),
            ),
           ],
        ),
      ),
    );
  }
}
