import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _showControls = true;
      } else {
        _controller.play();
        _showControls = true;
      }
    });

    if (_controller.value.isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _controller.value.isPlaying && !_isDragging) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _onProgressChanged(double value) {
    final duration = _controller.value.duration;
    final newPosition = Duration(
      milliseconds: (duration.inMilliseconds * value).round(),
    );
    _controller.seekTo(newPosition);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
        if (_showControls && _controller.value.isPlaying) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _controller.value.isPlaying && !_isDragging) {
              setState(() {
                _showControls = false;
              });
            }
          });
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),


          if (_showControls || !_controller.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),


          if (_showControls || !_controller.value.isPlaying)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [

                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.blue,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.blue,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayColor: Colors.blue.withOpacity(0.2),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _controller.value.position.inMilliseconds.toDouble(),
                        min: 0,
                        max: _controller.value.duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          setState(() {
                            _isDragging = true;
                          });
                          _onProgressChanged(value / _controller.value.duration.inMilliseconds);
                        },
                        onChangeStart: (value) {
                          setState(() {
                            _isDragging = true;
                          });
                        },
                        onChangeEnd: (value) {
                          setState(() {
                            _isDragging = false;
                            _showControls = true;
                          });
                          if (_controller.value.isPlaying) {
                            Future.delayed(const Duration(seconds: 3), () {
                              if (mounted && _controller.value.isPlaying && !_isDragging) {
                                setState(() {
                                  _showControls = false;
                                });
                              }
                            });
                          }
                        },
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_controller.value.position),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDuration(_controller.value.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
    )
        : Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      ),
    );
  }
}