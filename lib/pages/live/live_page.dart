import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 直播间页面（纯 UI 展示版）
// 布局参考：抖音直播间全屏沉浸式设计
//
// 保留区域：
//   - 顶部：主播信息（左）+ 观众信息+关闭（右）
//   - 左下：聊天弹幕区（带半透明黑色背景）
//   - 底部：输入框(60%宽)+表情、购物车、礼物、分享
// 暂不实现：视频播放、弹幕逻辑、礼物动画
// ═══════════════════════════════════════════════════════════════════════════

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  // ── 状态 ──────────────────────────────────────────────────────────────────
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 模拟弹幕数据
  final List<_DanmakuItem> _danmakuList = [
    const _DanmakuItem('真真不悔', '主播好美呀', Color(0xFFE91E63)),
    const _DanmakuItem('老班长启玉', '这个笑容我心动了', Color(0xFFFF5722)),
    const _DanmakuItem('西二旗华仔', '画质清晰，点赞！', Color(0xFF9C27B0)),
    const _DanmakuItem('小米女神', '第一次来，支持一下', Color(0xFF2196F3)),
    const _DanmakuItem('回龙观猫猫', '这也太好看了吧', Color(0xFF4CAF50)),
    const _DanmakuItem('北漂小王', '求关注求关注', Color(0xFF00BCD4)),
  ];

  // 是否显示输入模式
  bool _showInput = false;

  // ════════════════════════════════════════════════════════════════════════
  // 生命周期
  // ════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // 构建
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. 背景：视频区域（全屏） ─────────────────────────────────
          _buildVideoBackground(),

          // ── 2. 顶部渐变遮罩 ───────────────────────────────────────────
          _buildTopGradient(),

          // ── 3. 顶部区域 ─────────────────────────────────────────────
          _buildTopBar(),

          // ── 4. 底部操作栏 ───────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),

          // ── 5. 左下：聊天弹幕区 ─────────────────────────────────────
          if (!_showInput) _buildDanmakuArea(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 区域构建
  // ════════════════════════════════════════════════════════════════════════

  /// 视频背景区域
  Widget _buildVideoBackground() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv, size: 64, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              '直播间视频区域',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              '（视频播放器待接入）',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部渐变遮罩
  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
      ),
    );
  }

  /// 顶部栏：左上主播信息 + 右上观众+关闭
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildAnchorInfo()),
            _buildViewerInfo(),
          ],
        ),
      ),
    );
  }

  /// 主播信息区域（尺寸已调小）
  Widget _buildAnchorInfo() {
    return Row(
      children: [
        // 主播头像（小尺寸）
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF3A3A3A),
            child: Icon(Icons.person, color: Colors.white70, size: 20),
          ),
        ),
        const SizedBox(width: 8),

        // 名称 + 粉丝数
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '小毛驴的毛…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '粉丝 938',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 11,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),

        // 关注按钮（小尺寸红色胶囊）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            '关注',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 观众信息区域（头像重叠更紧密）
  Widget _buildViewerInfo() {
    return Row(
      children: [
        // 观众头像列表（重叠样式，间距更小）
        SizedBox(
          width: 70,
          height: 28,
          child: Stack(
            children: [
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 22.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [
                        Colors.purple[200],
                        Colors.teal[200],
                        Colors.orange[200],
                      ][i],
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // 在线人数
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility, color: Colors.white70, size: 14),
              SizedBox(width: 4),
              Text(
                '8888',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // 关闭按钮
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  /// 聊天弹幕区（左下角，每条带半透明黑色背景）
  Widget _buildDanmakuArea() {
    return Positioned(
      left: 8,
      bottom: 72,
      width: MediaQuery.of(context).size.width * 0.65,
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _danmakuList.length,
          itemBuilder: (context, index) {
            final item = _danmakuList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: item.username,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: item.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 底部操作栏
  Widget _buildBottomBar() {
    if (_showInput) {
      return _buildInputMode();
    }
    return _buildActionBar();
  }

  /// 普通模式底部操作栏
  Widget _buildActionBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPadding + 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Row(
        children: [
          // ── 输入框（60%宽）+ 表情 ─────────────────────────────────
          Expanded(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showInput = true),
                    child: const Text(
                      '说点什么…',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showToast('表情面板（待实现）'),
                  child: const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(width: 8),

          // 购物车
          _buildBottomBtn(
            icon: Icons.shopping_cart_outlined,
            onTap: () => _showToast('购物车'),
          ),

          const SizedBox(width: 8),

          // 礼物
          _buildBottomBtn(
            icon: Icons.card_giftcard,
            color: Colors.orange[300]!,
            onTap: () => _showToast('礼物'),
          ),

          const SizedBox(width: 8),

          // 分享
          _buildBottomBtn(
            icon: Icons.share_outlined,
            onTap: () => _showToast('分享'),
          ),
        ],
      ),
    );
  }

  /// 输入模式底部栏
  Widget _buildInputMode() {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPadding + 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
      ),
      child: Row(
        children: [
          // 文本输入框
          Expanded(
            child: TextField(
              controller: _chatController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '说点什么…',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF3A3A3A),
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
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // 发送按钮
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
          const SizedBox(width: 6),

          // 收起键盘
          GestureDetector(
            onTap: () => setState(() => _showInput = false),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF3A3A3A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white70, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  /// 底部单个操作按钮
  Widget _buildBottomBtn({
    required IconData icon,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 交互方法（纯 UI 占位）
  // ════════════════════════════════════════════════════════════════════════

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _danmakuList.add(_DanmakuItem('我', text, Colors.red));
      _chatController.clear();
      _showInput = false;
    });
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

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 数据模型
// ═══════════════════════════════════════════════════════════════════════════

class _DanmakuItem {
  final String username;
  final String content;
  final Color color;

  const _DanmakuItem(this.username, this.content, this.color);
}
