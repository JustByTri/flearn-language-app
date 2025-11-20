import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SimpleVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const SimpleVideoPlayer({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  State<SimpleVideoPlayer> createState() =>
      _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState
    extends State<SimpleVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _VideoPlayerContent(url: widget.videoUrl),
        ),
      ),
    );
  }
}

// Widget con để tách riêng Future → tránh rebuild lỗi
class _VideoPlayerContent extends StatefulWidget {
  final String url;
  const _VideoPlayerContent({required this.url});

  @override
  State<_VideoPlayerContent> createState() =>
      _VideoPlayerContentState();
}

class _VideoPlayerContentState
    extends State<_VideoPlayerContent> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.network(widget.url);

    try {
      await _controller.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red.shade600,
          handleColor: Colors.red.shade800,
          backgroundColor: Colors.grey.shade400,
          bufferedColor: Colors.grey.shade300,
        ),
        placeholder: Container(
          color: Colors.black87,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 4,
            ),
          ),
        ),
        errorBuilder: (_, error) => Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white70,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  "Không tải được video",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );

      if (mounted)
        setState(
              () {},
        ); // chỉ setState khi đã có controller
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Luôn luôn có placeholder đẹp khi đang load hoặc lỗi
    if (_chewieController == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 4,
          ),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}



