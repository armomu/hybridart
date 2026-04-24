import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// ══════════════════════════════════════════════════════════════════════════
// 可见性检测 Widget
// ══════════════════════════════════════════════════════════════════════════

class WidgetVisibilityInfo {
  final double visibleFraction;
  const WidgetVisibilityInfo(this.visibleFraction);
}

typedef VisibilityChangedCallback = void Function(WidgetVisibilityInfo);

class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final VisibilityChangedCallback onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisibilityChanged(const WidgetVisibilityInfo(1.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════════════════════════════════════

class VideoData {
  final String url;
  final String username;
  final String desc;
  final int likes;
  final int comments;
  final int favorites;
  final int shares;

  const VideoData({
    required this.url,
    required this.username,
    required this.desc,
    required this.likes,
    required this.comments,
    required this.favorites,
    required this.shares,
  });
}

// 视频数据列表
final List<VideoData> videoList = [
  const VideoData(
    url: 'https://www.pexels.com/zh-cn/download/video/37235780/',
    username: '@小猫咪',
    desc: '小猫咪，请给我来点cats~ 🐱',
    likes: 35640,
    comments: 13280,
    favorites: 8520,
    shares: 6720,
  ),
  const VideoData(
    url: 'https://www.w3schools.com/html/mov_bbb.mp4',
    username: '@蝴蝶记录者',
    desc: '诗和远方，一起去旅行吧~ 🌊',
    likes: 12800,
    comments: 5200,
    favorites: 3300,
    shares: 2100,
  ),
  const VideoData(
    url: 'https://www.pexels.com/download/video/33538187/',
    username: '@自然探索',
    desc: '慢下来，感受生活的美好 ✨',
    likes: 28900,
    comments: 9100,
    favorites: 6200,
    shares: 4300,
  ),
  const VideoData(
    url: 'https://www.w3schools.com/html/movie.mp4',
    username: '@海边的风',
    desc: '海浪声是最好的白噪音 🌊',
    likes: 19200,
    comments: 7600,
    favorites: 4500,
    shares: 3200,
  ),
];

// ══════════════════════════════════════════════════════════════════════════
// 视频流控制器 — 关注/精选共享
// ══════════════════════════════════════════════════════════════════════════

class VideoFeedController {
  int currentPage = 0;
  bool isFeedActive = false;

  void onPageChanged(int index) => currentPage = index;
}

// ══════════════════════════════════════════════════════════════════════════
// 视频流视图 — 关注和精选共用
// ══════════════════════════════════════════════════════════════════════════

class VideoFeedView extends StatefulWidget {
  final VideoFeedController controller;
  final int tabIndex;

  const VideoFeedView({
    required this.controller,
    required this.tabIndex,
    super.key,
  });

  @override
  State<VideoFeedView> createState() => _VideoFeedViewState();
}

class _VideoFeedViewState extends State<VideoFeedView>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  bool _isViewVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: widget.controller.currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(WidgetVisibilityInfo info) {
    final visible = info.visibleFraction > 0.1;
    if (visible != _isViewVisible) {
      setState(() {
        _isViewVisible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videoList.length,
        onPageChanged: (index) {
          widget.controller.onPageChanged(index);
          setState(() {});
        },
        itemBuilder: (context, index) {
          return VideoPage(
            data: videoList[index],
            isActive: index == widget.controller.currentPage,
            lazyLoad: !_isViewVisible,
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 单个视频页
// ══════════════════════════════════════════════════════════════════════════

class VideoPage extends StatefulWidget {
  final VideoData data;
  final bool isActive;
  final bool lazyLoad;

  const VideoPage({
    required this.data,
    required this.isActive,
    this.lazyLoad = false,
    super.key,
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = true;
  bool _showPlayIcon = false;
  String? _errorMessage;
  bool _isLandscapeVideo = false;

  @override
  void initState() {
    super.initState();
    if (!widget.lazyLoad) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lazyLoad &&
        widget.isActive &&
        !oldWidget.isActive &&
        !_initialized) {
      _initVideo();
    }
    if (!_initialized) return;
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
      setState(() => _isPlaying = true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  Future<void> _initVideo() async {
    if (_controller != null) return;
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.data.url),
      );
      await _controller!.initialize();
      _controller!.setLooping(true);
      final aspectRatio = _controller!.value.aspectRatio;
      _isLandscapeVideo = aspectRatio >= 1.4;
      if (widget.isActive) {
        _controller!.play();
      }
      if (mounted) {
        setState(() {
          _initialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('视频初始化失败: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '视频加载失败，请检查网络或视频地址';
        });
      }
    }
  }

  Future<void> _enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenVideoPage(
          controller: _controller!,
        ),
      ),
    );
    _exitFullScreen();
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized || _controller == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
      _showPlayIcon = true;
      if (_isPlaying) {
        _controller!.play();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _isPlaying) setState(() => _showPlayIcon = false);
        });
      } else {
        _controller!.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),

          if (_initialized && _controller != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  if (_isLandscapeVideo)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: () {
                          _enterFullScreen();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 0.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.screen_rotation,
                                  color: Colors.white70, size: 16),
                              SizedBox(width: 4),
                              Text('横屏观看',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white70, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _initialized = false;
                      });
                      _initVideo();
                    },
                    child:
                        const Text('重试', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          if (_showPlayIcon)
            Center(
              child: AnimatedOpacity(
                opacity: _showPlayIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),

          if (_initialized && _controller != null)
            Positioned(
              right: 10,
              bottom: 120,
              child: _buildRightActions(),
            ),

          if (_initialized && _controller != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildProgressBar(),
            ),

          if (_initialized && _controller != null)
            Positioned(
              left: 16,
              right: 80,
              bottom: 30,
              child: _buildBottomInfo(),
            ),
        ],
      ),
    );
  }

  Widget _buildRightActions() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[700],
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            Positioned(
              bottom: -8,
              left: 12,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildActionButton(
            icon: Icons.favorite, color: Colors.red, count: widget.data.likes),
        const SizedBox(height: 20),
        _buildActionButton(
            icon: Icons.chat_bubble_rounded,
            color: Colors.white,
            count: widget.data.comments),
        const SizedBox(height: 20),
        _buildActionButton(
            icon: Icons.star_rounded,
            color: Colors.amber,
            count: widget.data.favorites),
        const SizedBox(height: 20),
        _buildActionButton(
            icon: Icons.reply,
            color: Colors.white,
            count: widget.data.shares,
            flipHorizontal: true),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int count,
    bool flipHorizontal = false,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: flipHorizontal
                ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0))
                : Matrix4.identity(),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.data.username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.data.desc,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (_controller == null || !_initialized) return const SizedBox.shrink();

    return ValueListenableBuilder(
      valueListenable: _controller!,
      builder: (context, VideoPlayerValue value, child) {
        final position = value.position;
        final duration = value.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            trackHeight: 2,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0).toDouble(),
            onChanged: (value) {
              final newPosition = duration * value;
              _controller!.seekTo(newPosition);
            },
          ),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 全屏视频页面（横屏观看体验）
// ══════════════════════════════════════════════════════════════════════════

class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPage({
    required this.controller,
    super.key,
  });

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  bool _showControls = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: MediaQuery.of(context).size.height *
                      controller.value.aspectRatio,
                  height: MediaQuery.of(context).size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),

            if (_showControls) ...[
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              Center(
                child: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, VideoPlayerValue value, child) {
                    return GestureDetector(
                      onTap: () {
                        if (value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                        setState(() {});
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: _buildFullScreenProgressBar(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenProgressBar() {
    if (!widget.controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    String fmt(Duration d) {
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return ValueListenableBuilder(
      valueListenable: widget.controller,
      builder: (context, VideoPlayerValue value, child) {
        final position = value.position;
        final duration = value.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
                trackHeight: 2,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0).toDouble(),
                onChanged: (value) {
                  final newPosition = duration * value;
                  widget.controller.seekTo(newPosition);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmt(position),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(fmt(duration),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
