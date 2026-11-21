import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../utils/media_validator.dart';

class FullscreenImageViewer {
  static void show(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.black54,
                    child: const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double height;
  final BorderRadius? borderRadius;

  const InlineVideoPlayer({
    super.key,
    required this.videoUrl,
    this.height = 200,
    this.borderRadius,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller = ctrl;
      await ctrl.initialize();
      ctrl.addListener(_onPlayerTick);
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _onPlayerTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerTick);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(14);

    if (_hasError) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          height: widget.height,
          width: double.infinity,
          color: Colors.black87,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_outline_rounded, color: Colors.white70, size: 38),
              const SizedBox(height: 8),
              const Text(
                'Video siap diputar di pemutar eksternal',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _openExternal,
                icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF34D399)),
                label: const Text(
                  'Buka Video',
                  style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          height: widget.height,
          width: double.infinity,
          color: context.isDark ? AppTheme.darkSurface : const Color(0xFF0F172A),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2.5),
          ),
        ),
      );
    }

    final ctrl = _controller!;
    final isPlaying = ctrl.value.isPlaying;

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (isPlaying) {
                  ctrl.pause();
                } else {
                  ctrl.play();
                }
              },
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: ctrl.value.size.width,
                    height: ctrl.value.size.height,
                    child: VideoPlayer(ctrl),
                  ),
                ),
              ),
            ),
            if (!isPlaying)
              GestureDetector(
                onTap: () => ctrl.play(),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMuted = !_isMuted;
                    ctrl.setVolume(_isMuted ? 0 : 1);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                ctrl,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF10B981),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YoutubeCardPreview extends StatelessWidget {
  final String youtubeUrl;
  final double height;
  final BorderRadius? borderRadius;

  const YoutubeCardPreview({
    super.key,
    required this.youtubeUrl,
    this.height = 200,
    this.borderRadius,
  });

  Future<void> _openYoutube() async {
    final uri = Uri.tryParse(youtubeUrl.trim());
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbUrl = MediaValidator.youtubeThumbnailUrl(youtubeUrl);
    final radius = borderRadius ?? BorderRadius.circular(16);

    return GestureDetector(
      onTap: _openYoutube,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          height: height,
          width: double.infinity,
          color: const Color(0xFF0F172A),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbUrl != null)
                Image.network(
                  thumbUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.play_circle_fill_rounded, color: Colors.redAccent, size: 54),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 6),
                      Text(
                        'Tonton di YouTube',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
