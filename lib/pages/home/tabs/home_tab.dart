import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 首页 Tab - 静态UI（支持亮色/暗色主题）
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _funcPageController = PageController();
  int _funcPageIndex = 0;

  @override
  void dispose() {
    _funcPageController.dispose();
    super.dispose();
  }

  // ================================================================
  // 主题色抽取引擎
  // ================================================================
  _HomeColors get _c {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _HomeColors(
      isDark: isDark,
      scaffoldBg: theme.scaffoldBackgroundColor,
      card: colorScheme.surface,
      cardShadow: isDark
          ? Colors.black.withOpacity(0.3)
          : Colors.black.withOpacity(0.05),
      textPrimary: colorScheme.onSurface,
      textSecondary: colorScheme.onSurface.withOpacity(0.6),
      textHint: colorScheme.onSurface.withOpacity(0.4),
      divider: colorScheme.outlineVariant,
      searchBg: colorScheme.surface,
      primary: const Color(0xFF667eea), // 品牌主色（渐变起点）
      primaryLight: const Color(0xFF764ba2), // 渐变终点
      accent1: const Color(0xFFFF6B6B), // 红
      accent2: const Color(0xFF52C41A), // 绿
      accent3: const Color(0xFFFAAD14), // 黄
      white: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.scaffoldBg,
      body: Column(
        children: [
          // ========== 头部区域（渐变背景） ==========
          _buildHeader(context),

          // ========== 内容区域（可滚动 + 下拉刷新） ==========
          Expanded(
            child: RefreshIndicator(
              color: _c.primary,
              onRefresh: () async {
                // 模拟网络请求延迟
                await Future.delayed(const Duration(seconds: 1));
                if (mounted) {
                  Get.snackbar('', '刷新成功');
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // -------- 四个带Label的图标按钮 --------
                    _buildIconButtonsRow(),

                    const SizedBox(height: 16),

                    // -------- 可左右滑动的功能卡片 --------
                    _buildFunctionCard(),

                    const SizedBox(height: 16),

                    // -------- 消息通知横条 --------
                    _buildNotificationBanner(),

                    const SizedBox(height: 16),

                    // -------- 16:9 区块组合 --------
                    _buildFeaturedBlocks(),

                    const SizedBox(height: 16),

                    // -------- 信息列表 --------
                    _buildInfoList(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 头部栏 - 渐变背景（渐变色不变，保持品牌感）
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _c.primary,
            _c.primaryLight,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 左边 - 我的图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _c.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person,
                  color: _c.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // 中间 - 搜索输入框
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: _c.searchBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('点击了搜索框')),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: '搜索内容...',
                      hintStyle: TextStyle(
                        color: _c.textHint,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _c.textHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 右边 - 通知图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _c.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.notifications,
                        color: _c.white,
                        size: 24,
                      ),
                    ),
                    // 通知红点
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 四个带Label的图标按钮（无背景）
  Widget _buildIconButtonsRow() {
    final icons = [
      {'icon': Icons.qr_code, 'label': '扫码'},
      {'icon': Icons.payment, 'label': '付款'},
      {'icon': Icons.savings, 'label': '储蓄'},
      {'icon': Icons.more_horiz, 'label': '更多'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: icons.map((item) {
          return Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _c.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _c.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: 28,
                  color: _c.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: _c.textPrimary,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 可左右滑动的功能卡片（PageView，每页 2行×5列=10个图标）
  Widget _buildFunctionCard() {
    // 每页 10 个图标（2行×5列），目前 2 页
    final pages = [
      [
        {'icon': Icons.local_play, 'label': '优惠券'},
        {'icon': Icons.shopping_cart, 'label': '购物车'},
        {'icon': Icons.history, 'label': '历史'},
        {'icon': Icons.favorite, 'label': '收藏'},
        {'icon': Icons.card_giftcard, 'label': '礼品卡'},
        {'icon': Icons.credit_card, 'label': '银行卡'},
        {'icon': Icons.location_on, 'label': '地址'},
        {'icon': Icons.security, 'label': '安全'},
        {'icon': Icons.help, 'label': '帮助'},
        {'icon': Icons.settings, 'label': '设置'},
      ],
      [
        {'icon': Icons.directions_car, 'label': '出行'},
        {'icon': Icons.flight, 'label': '旅行'},
        {'icon': Icons.hotel, 'label': '酒店'},
        {'icon': Icons.restaurant, 'label': '美食'},
        {'icon': Icons.local_hospital, 'label': '医疗'},
        {'icon': Icons.school, 'label': '教育'},
        {'icon': Icons.sports_esports, 'label': '游戏'},
        {'icon': Icons.movie, 'label': '影视'},
        {'icon': Icons.music_note, 'label': '音乐'},
        {'icon': Icons.photo_camera, 'label': '摄影'},
      ],
    ];

    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _c.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // PageView 图标区域
          Expanded(
            child: PageView.builder(
              controller: _funcPageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _funcPageIndex = index);
              },
              itemBuilder: (context, pageIndex) {
                final icons = pages[pageIndex];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                  child: Column(
                    children: [
                      // 第一行 5 个
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: icons
                            .take(5)
                            .map((e) => _buildFunctionItem(
                                  icon: e['icon'] as IconData,
                                  label: e['label'] as String,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      // 第二行 5 个
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: icons
                            .skip(5)
                            .map((e) => _buildFunctionItem(
                                  icon: e['icon'] as IconData,
                                  label: e['label'] as String,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 底部分页指示器
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) {
                final active = i == _funcPageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? _c.primary : _c.textHint,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionItem({required IconData icon, required String label}) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: _c.primary),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: _c.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 消息通知横条
  Widget _buildNotificationBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _c.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _c.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _c.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '公告',
              style: TextStyle(
                color: _c.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '欢迎使用 HybridArt 应用，更多精彩功能等您探索！',
              style: TextStyle(fontSize: 13, color: _c.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right, color: _c.textHint, size: 20),
        ],
      ),
    );
  }

  /// 16:9 区块组合
  Widget _buildFeaturedBlocks() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 左边 40% 竖形块（渐变背景，保持品牌感）
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_c.primary, _c.primaryLight],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Text(
                      '精选推荐',
                      style: TextStyle(
                        color: _c.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Text(
                      '更多精彩',
                      style: TextStyle(
                        color: _c.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Icon(
                      Icons.arrow_forward,
                      color: _c.white.withOpacity(0.5),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 右边 60% 上下两块
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // 上边横块
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _c.card,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _c.cardShadow,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '限时优惠',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '立即查看',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: _c.accent1.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_offer,
                            color: _c.accent1,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 下边两个小块
                Expanded(
                  child: Row(
                    children: [
                      // 左小块 - 新用户（图标+文字）
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: _c.card,
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _c.cardShadow,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _c.accent2.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.card_giftcard,
                                  color: _c.accent2,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '新用户',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 右小块 - 签到（图标+文字）
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: _c.card,
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _c.cardShadow,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _c.accent3.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: _c.accent3,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '签到',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 信息列表
  Widget _buildInfoList() {
    final items = [
      {
        'icon': Icons.trending_up,
        'title': '热门资讯',
        'subtitle': '查看最新动态',
        'color': _c.accent1,
      },
      {
        'icon': Icons.new_releases,
        'title': '新功能上线',
        'subtitle': '了解最新功能',
        'color': _c.primary,
      },
      {
        'icon': Icons.star,
        'title': '用户好评',
        'subtitle': '看看大家怎么说',
        'color': _c.accent3,
      },
      {
        'icon': Icons.support_agent,
        'title': '联系客服',
        'subtitle': '遇到问题？联系我们',
        'color': _c.accent2,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _c.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 列表头
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '便捷服务',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _c.textPrimary,
                  ),
                ),
                Text(
                  '查看全部 >',
                  style: TextStyle(
                    fontSize: 12,
                    color: _c.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 分割线
          Container(height: 1, color: _c.divider),

          // 列表项
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _c.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: _c.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: _c.textSecondary,
                  ),
                  onTap: () {},
                ),
                if (index < items.length - 1)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 70),
                    color: _c.divider.withOpacity(0.5),
                  ),
              ],
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 首页专属主题色抽取引擎
class _HomeColors {
  final bool isDark;
  final Color scaffoldBg;
  final Color card;
  final Color cardShadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color divider;
  final Color searchBg;
  final Color primary;
  final Color primaryLight;
  final Color accent1;
  final Color accent2;
  final Color accent3;
  final Color white;

  _HomeColors({
    required this.isDark,
    required this.scaffoldBg,
    required this.card,
    required this.cardShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.divider,
    required this.searchBg,
    required this.primary,
    required this.primaryLight,
    required this.accent1,
    required this.accent2,
    required this.accent3,
    required this.white,
  });
}
