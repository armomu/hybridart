import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 直播页面
// ═══════════════════════════════════════════════════════════════════════════

class LiveTab extends StatefulWidget {
  const LiveTab({super.key});

  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> with SingleTickerProviderStateMixin {
  late VlcPlayerController _vlcController;
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMessage> _chatMessages = [];

  // 播放状态
  bool _isPlaying = false;
  bool _isBuffering = true;
  String _errorMessage = '';

  // 模拟聊天数据
  final List<_ChatMessage> _mockMessages = [
    const _ChatMessage(username: '小明', content: '主播好棒！', color: Colors.pink),
    const _ChatMessage(
        username: '阳光', content: '这个风景太美了', color: Colors.orange),
    const _ChatMessage(
        username: '花开', content: '支持支持 👍', color: Colors.purple),
    const _ChatMessage(
        username: '星空', content: '请问这是在哪里拍的？', color: Colors.blue),
    const _ChatMessage(username: '云游', content: '好想出去玩啊', color: Colors.green),
  ];

  @override
  void initState() {
    super.initState();
    _initVlcPlayer();
    _tabController = TabController(length: 3, vsync: this);
    _chatMessages.addAll(_mockMessages);
  }

  void _initVlcPlayer() {
    _vlcController = VlcPlayerController.network(
      'rtmp://ns8.indexforce.com/home/mystream',
      autoPlay: true,
      hwAcc: HwAcc.full,
      options: VlcPlayerOptions(
        rtp: VlcRtpOptions([
          // RTMP 流优化选项
          '--rtsp-tcp',
          '--live-caching=0',
          '--file-caching=300',
          '--network-caching=300',
        ]),
      ),
    );

    // 监听播放状态
    _vlcController.addListener(_onVlcPlayerStateChanged);
  }

  void _onVlcPlayerStateChanged() {
    if (!mounted) return;
    setState(() {
      _isPlaying = _vlcController.value.isPlaying;
      _isBuffering = _vlcController.value.isBuffering;
      if (_vlcController.value.hasError) {
        _errorMessage = _vlcController.value.errorDescription ?? '播放错误';
      }
    });
  }

  @override
  void dispose() {
    _vlcController.removeListener(_onVlcPlayerStateChanged);
    _vlcController.dispose();
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add(_ChatMessage(
        username: '我',
        content: text,
        color: Colors.red,
      ));
    });
    _chatController.clear();

    // 滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      // 通知聊天列表滚动
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 直播画面区域
        Expanded(
          flex: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 视频播放器
              VlcPlayer(
                controller: _vlcController,
                aspectRatio: 16 / 9,
                placeholder: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          _isBuffering ? '正在连接直播...' : '等待直播开始',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 播放/暂停按钮覆盖层
              if (!_isPlaying && !_isBuffering)
                Center(
                  child: GestureDetector(
                    onTap: () => _vlcController.play(),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),

              // 错误提示
              if (_errorMessage.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() => _errorMessage = '');
                            _vlcController.play();
                          },
                          child: const Text('重试',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),

              // 顶部渐变遮罩 + 标题
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 直播标题
              Positioned(
                top: 10,
                left: 16,
                child: Row(
                  children: [
                    // 直播间头像
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[700],
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'HK直播',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '1234 人在看',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 右上方关闭按钮
              Positioned(
                top: 10,
                right: 16,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),

              // 底部互动卡片
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    _buildActionIcon(Icons.share, '分享'),
                    const SizedBox(height: 12),
                    _buildActionIcon(Icons.favorite_border, '点赞'),
                    const SizedBox(height: 12),
                    _buildActionIcon(Icons.volume_up, '静音'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 下方 Tab 区域
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Tab 栏
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.red,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.red,
                  indicatorWeight: 2,
                  tabs: const [
                    Tab(text: '聊天'),
                    Tab(text: '投票'),
                    Tab(text: '赛况'),
                  ],
                ),
              ),

              // Tab 内容
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 聊天页面
                    _buildChatView(),
                    // 投票页面
                    _buildPlaceholderView('投票功能开发中...'),
                    // 赛况页面
                    _buildPlaceholderView('赛况功能开发中...'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 聊天视图
  Widget _buildChatView() {
    return Column(
      children: [
        // 聊天消息列表
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13),
                      children: [
                        TextSpan(
                          text: '${msg.username}: ',
                          style: TextStyle(
                            color: msg.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: msg.content,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 输入框区域
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: '说点什么...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 占位视图（投票/赛况）
  Widget _buildPlaceholderView(String text) {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 右侧操作图标按钮
  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(icon, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 聊天消息模型
// ═══════════════════════════════════════════════════════════════════════════

class _ChatMessage {
  final String username;
  final String content;
  final Color color;

  const _ChatMessage({
    required this.username,
    required this.content,
    required this.color,
  });
}
