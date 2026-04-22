import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 数据模型
// ═══════════════════════════════════════════════════════════════════════════

class _VideoData {
  final String url;
  final String username;
  final String desc;
  final int likes;
  final int comments;
  final int favorites;
  final int shares;

  const _VideoData({
    required this.url,
    required this.username,
    required this.desc,
    required this.likes,
    required this.comments,
    required this.favorites,
    required this.shares,
  });
}

class _NearbyPost {
  final String title;
  final String subtitle;
  final String coverUrl;

  const _NearbyPost({
    required this.title,
    required this.subtitle,
    required this.coverUrl,
  });
}

/// 两个公开可用的视频链接，循环复用
final List<_VideoData> _videoList = [
  const _VideoData(
    url: 'https://www.pexels.com/download/video/33538187/',
    username: '@蝴蝶记录者',
    desc: '大自然的奇妙瞬间，每一帧都是惊喜 🦋',
    likes: 35640,
    comments: 13280,
    favorites: 8520,
    shares: 6720,
  ),
  const _VideoData(
    url: 'https://www.w3schools.com/html/mov_bbb.mp4',
    username: '@旅行日记',
    desc: '诗和远方，一起去旅行吧~ 🌊',
    likes: 12800,
    comments: 5200,
    favorites: 3300,
    shares: 2100,
  ),
  const _VideoData(
    url: 'https://www.pexels.com/download/video/33538187/',
    username: '@自然探索',
    desc: '慢下来，感受生活的美好 ✨',
    likes: 28900,
    comments: 9100,
    favorites: 6200,
    shares: 4300,
  ),
  const _VideoData(
    url: 'https://www.w3schools.com/html/mov_bbb.mp4',
    username: '@海边的风',
    desc: '海浪声是最好的白噪音 🌊',
    likes: 19200,
    comments: 7600,
    favorites: 4500,
    shares: 3200,
  ),
];

/// 同城模拟图文数据
final List<_NearbyPost> _nearbyPosts = [
  const _NearbyPost(
      title: '街头美食探店',
      subtitle: '@吃货小王 · 2.3km',
      coverUrl: 'https://picsum.photos/seed/food1/200/200'),
  const _NearbyPost(
      title: '城市夜景摄影',
      subtitle: '@摄影师老李 · 1.8km',
      coverUrl: 'https://picsum.photos/seed/night1/200/200'),
  const _NearbyPost(
      title: '周末骑行记录',
      subtitle: '@骑行侠 · 5.1km',
      coverUrl: 'https://picsum.photos/seed/bike1/200/200'),
  const _NearbyPost(
      title: '公园跑步日常',
      subtitle: '@运动达人 · 0.8km',
      coverUrl: 'https://picsum.photos/seed/run1/200/200'),
  const _NearbyPost(
      title: '手工咖啡分享',
      subtitle: '@咖啡控 · 3.2km',
      coverUrl: 'https://picsum.photos/seed/coffee1/200/200'),
  const _NearbyPost(
      title: '萌宠日常',
      subtitle: '@铲屎官 · 1.5km',
      coverUrl: 'https://picsum.photos/seed/pet1/200/200'),
  const _NearbyPost(
      title: '读书笔记分享',
      subtitle: '@书虫 · 4.0km',
      coverUrl: 'https://picsum.photos/seed/book1/200/200'),
  const _NearbyPost(
      title: '手绘涂鸦作品',
      subtitle: '@画手小白 · 2.7km',
      coverUrl: 'https://picsum.photos/seed/art1/200/200'),
  const _NearbyPost(
      title: '健身打卡记录',
      subtitle: '@肌肉小哥 · 1.2km',
      coverUrl: 'https://picsum.photos/seed/gym1/200/200'),
  const _NearbyPost(
      title: '街头音乐现场',
      subtitle: '@民谣歌手 · 3.8km',
      coverUrl: 'https://picsum.photos/seed/music1/200/200'),
];

// ═══════════════════════════════════════════════════════════════════════════
// 主 Tab 入口 — 三个 Tab 水平滑动
// ═══════════════════════════════════════════════════════════════════════════

class ShortVideoTab extends StatefulWidget {
  const ShortVideoTab({super.key});

  @override
  State<ShortVideoTab> createState() => _ShortVideoTabState();
}

class _ShortVideoTabState extends State<ShortVideoTab>
    with AutomaticKeepAliveClientMixin {
  int _topTabIndex = 1; // 默认「精选」
  late PageController _tabPageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _tabPageController.dispose();
    super.dispose();
  }

  /// 「关注」和「精选」共用同一个视频 Feed
  VideoFeedController? _sharedFeedController;

  VideoFeedController _getSharedFeedController() {
    return _sharedFeedController ??= VideoFeedController();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: _buildTopBar(),
        body: PageView(
          controller: _tabPageController,
          onPageChanged: (index) {
            setState(() => _topTabIndex = index);
          },
          children: [
            // 关注 — 与精选共用视频流
            _VideoFeedView(
                controller: _getSharedFeedController(), tabIndex: _topTabIndex),
            // 精选 — 与关注共用视频流
            _VideoFeedView(
                controller: _getSharedFeedController(), tabIndex: _topTabIndex),
            // 同城 — 图文左右双列
            _NearbyView(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    const titles = ['关注', '精选', '同城'];

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: titles.asMap().entries.map((e) {
          final active = e.key == _topTabIndex;
          return GestureDetector(
            onTap: () {
              _tabPageController.animateToPage(
                e.key,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.value,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontSize: active ? 16 : 15,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 20,
                    height: 2,
                    color: active ? Colors.white : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 视频流控制器 — 关注/精选共享
// ═══════════════════════════════════════════════════════════════════════════

class VideoFeedController {
  int currentPage = 0;
  bool isFeedActive = false;

  void onPageChanged(int index) => currentPage = index;
}

// ═══════════════════════════════════════════════════════════════════════════
// 视频流视图 — 关注和精选共用
// ═══════════════════════════════════════════════════════════════════════════

class _VideoFeedView extends StatefulWidget {
  final VideoFeedController controller;
  final int tabIndex;

  const _VideoFeedView({
    required this.controller,
    required this.tabIndex,
  });

  @override
  State<_VideoFeedView> createState() => _VideoFeedViewState();
}

class _VideoFeedViewState extends State<_VideoFeedView>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('_VideoFeedView initState============================');
    _pageController =
        PageController(initialPage: widget.controller.currentPage);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 判断这个 feed 是否处于可见 Tab
    final isActive = (widget.controller.currentPage >= 0);
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videoList.length,
      onPageChanged: (index) {
        widget.controller.onPageChanged(index);
        setState(() {});
      },
      itemBuilder: (context, index) {
        return _VideoPage(
          data: _videoList[index],
          isActive: index == widget.controller.currentPage,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 同城视图 — 图文左右双列布局
// ═══════════════════════════════════════════════════════════════════════════

class _NearbyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        itemCount: (_nearbyPosts.length / 2).ceil(),
        itemBuilder: (context, rowIndex) {
          final left = _nearbyPosts[rowIndex * 2];
          final right = rowIndex * 2 + 1 < _nearbyPosts.length
              ? _nearbyPosts[rowIndex * 2 + 1]
              : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _NearbyCard(post: left)),
                if (right != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _NearbyCard(post: right)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final _NearbyPost post;
  const _NearbyCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 封面图
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              post.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, color: Colors.grey, size: 40),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ),
          // 文字信息
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  post.subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 单个视频页（保持不变）
// ═══════════════════════════════════════════════════════════════════════════

class _VideoPage extends StatefulWidget {
  final _VideoData data;
  final bool isActive;

  const _VideoPage({required this.data, required this.isActive});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isPlaying = true;
  bool _showPlayIcon = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.data.url),
    );
    await _controller.initialize();
    _controller.setLooping(true);
    if (widget.isActive) {
      _controller.play();
    }
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  void didUpdateWidget(_VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) return;
    if (widget.isActive && !oldWidget.isActive) {
      _controller.play();
      setState(() => _isPlaying = true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized) return;
    setState(() {
      _isPlaying = !_isPlaying;
      _showPlayIcon = true;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showPlayIcon = false);
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
          if (_initialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
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
                    _isPlaying ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),

          // 右侧操作栏
          Positioned(
            right: 10,
            bottom: 120,
            child: _buildRightActions(),
          ),

          // 底部信息栏
          Positioned(
            left: 16,
            right: 80,
            bottom: 40,
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

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }
}
