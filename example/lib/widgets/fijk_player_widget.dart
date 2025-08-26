import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';

class FijkPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isLive;
  final bool autoPlay;

  const FijkPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.isLive = true,
    this.autoPlay = true,
  }) : super(key: key);

  @override
  State<FijkPlayerWidget> createState() => _FijkPlayerWidgetState();
}

class _FijkPlayerWidgetState extends State<FijkPlayerWidget> {
  final FijkPlayer player = FijkPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Cấu hình player cho RTSP streams
      await player.setOption(
          FijkOption.hostCategory, "enable-accurate-seek", 1);
      await player.setOption(FijkOption.hostCategory, "request-screen-on", 1);
      await player.setOption(FijkOption.hostCategory, "request-audio-focus", 1);

      // Cấu hình cho live streaming
      if (widget.isLive) {
        await player.setOption(
            FijkOption.playerCategory, "start-on-prepared", 1);
        await player.setOption(FijkOption.playerCategory, "mediacodec", 1);
        await player.setOption(
            FijkOption.playerCategory, "mediacodec-auto-rotate", 1);
        await player.setOption(FijkOption.playerCategory,
            "mediacodec-handle-resolution-change", 1);
      }

      // Set data source
      await player.setDataSource(widget.videoUrl, autoPlay: widget.autoPlay);

      // Listen to player events
      player.addListener(_playerListener);

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi khởi tạo FijkPlayer: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _playerListener() {
    if (!mounted) return;

    final state = player.state;
    setState(() {
      _isPlaying = state == FijkState.started;
      _isLoading =
          state == FijkState.initialized || state == FijkState.prepared;
    });
  }

  void _togglePlayPause() {
    if (player.state == FijkState.started) {
      player.pause();
    } else {
      player.start();
    }
  }

  void _refreshStream() {
    _initializePlayer();
  }

  @override
  void dispose() {
    player.removeListener(_playerListener);
    player.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Đang tải video...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Lỗi phát video',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshStream,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // FijkPlayer widget
          FijkView(
            player: player,
            fit: FijkFit.contain,
          ),

          // Video controls overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Play/Pause button
                  IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),

                  // Video info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isLive ? 'LIVE' : 'PLAYBACK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.videoUrl,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Refresh button
                  IconButton(
                    onPressed: _refreshStream,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                  ),

                  // Fullscreen button
                  IconButton(
                    onPressed: () {
                      // TODO: Implement fullscreen
                    },
                    icon: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
