import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 直播独立页面
// ═══════════════════════════════════════════════════════════════════════════

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage>
    with SingleTickerProviderStateMixin {
  late VlcPlayerController _vlcController;
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _chatMessages = [];

  // 播放状态
  bool _isPlaying = false;
  bool _isBuffering = true;
  String _errorMessage = '';

  // 模拟聊天数据
  static const List<_ChatMessage> _mockMessages = [
    _ChatMessage(username: '小明', content: '主播好棒！', color: Colors.pink),
    _ChatMessage(username: '阳光', content: '这个风景太美了', color: Colors.orange),
    _ChatMessage(username: '花开', content: '支持支持 👍', color: Colors.purple),
    _ChatMessage(username: '星空', content: '请问这是在哪里拍的？', color: Colors.blue),
    _ChatMessage(username: '云游', content: '好想出去玩啊', color: Colors.green),
    _ChatMessage(username: '晨曦', content: '第一次看直播，好激动', color: Colors.teal),
    _ChatMessage(username: '落叶', content: '画面很清晰！', color: Colors.indigo),
  ];

  @override
  void initState() {
    super.initState();
    _initVlcPlayer();
    _tabController = TabController(length: 3, vsync: this);
    _chatMessages.addAll(_mockMessages);
    // 沉浸式状态栏
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  void _initVlcPlayer() {
    _vlcController = VlcPlayerController.network(
      'rtmp://live.hkstv.hk.lxdns.com/live/hks',
      autoPlay: true,
      hwAcc: HwAcc.full,
      options: VlcPlayerOptions(
        rtp: VlcRtpOptions([
          '--rtsp-tcp',
          '--live-caching=0',
          '--network-caching=300',
        ]),
      ),
    );
    _vlcController.addListener(_onVlcStateChanged);
  }

  void _onVlcStateChanged() {
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
    _vlcController.removeListener(_onVlcStateChanged);
    _vlcController.dispose();
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(const _ChatMessage(
        username: '我',
        content: '',
        color: Colors.red,
      ).copyWith(content: text));
    });
    _chatController.clear();
    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── 直播视频区域 ──────────────────────────────────────────
            Expanded(
              flex: 5,
              child: _buildVideoArea(),
            ),
            // ── 下方互动 Tab 区域 ─────────────────────────────────────
            Expanded(
              flex: 4,
              child: _buildInteractionArea(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 视频区域
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildVideoArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // VLC 视频画面
        VlcPlayer(
          controller: _vlcController,
          aspectRatio: 16 / 9,
          placeholder: _buildLoadingPlaceholder(),
        ),

        // 加载/缓冲中遮罩
        if (_isBuffering && !_isPlaying)
          _buildLoadingPlaceholder(),

        // 未播放时显示播放按钮
        if (!_isPlaying && !_isBuffering && _errorMessage.isEmpty)
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
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
              ),
            ),
          ),

        // 错误提示
        if (_errorMessage.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.signal_wifi_off, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    '直播连接失败',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _errorMessage = '');
                      _vlcController.play();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重新连接'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 顶部渐变遮罩
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
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ),

        // 顶部左：返回 + 主播信息
        Positioned(
          top: 8,
          left: 4,
          right: 56,
          child: Row(
            children: [
              // 返回按钮
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                padding: const EdgeInsets.all(8),
              ),
              // 主播头像
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[700],
                child: const Icon(Icons.person, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              // 主播名 + 在线人数
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HK直播',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '1,234 人在看',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // 关注按钮
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+ 关注',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 顶部右：关闭
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),

        // 右侧操作栏
        Positioned(
          right: 12,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSideAction(Icons.share_outlined, '分享'),
              const SizedBox(height: 16),
              _buildSideAction(Icons.favorite_border, '点赞'),
              const SizedBox(height: 16),
              _buildSideAction(Icons.volume_up_outlined, '声音'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isBuffering ? '正在连接直播...' : '等待直播开始',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black38,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(icon, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 互动 Tab 区域
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInteractionArea() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Tab 栏
          TabBar(
            controller: _tabController,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.red,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: '聊天'),
              Tab(text: '投票'),
              Tab(text: '赛况'),
            ],
          ),

          // Tab 内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatView(),
                _buildPlaceholderView(Icons.how_to_vote_outlined, '投票功能开发中...'),
                _buildPlaceholderView(Icons.sports_score_outlined, '赛况功能开发中...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        // 消息列表
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${msg.username}  ',
                          style: TextStyle(
                            color: msg.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: msg.content,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 输入框
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: '说点什么...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[100],
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderView(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
        ],
      ),
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

  _ChatMessage copyWith({String? content}) {
    return _ChatMessage(
      username: username,
      content: content ?? this.content,
      color: color,
    );
  }
}
