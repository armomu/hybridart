import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'video_feed_view.dart';
import 'nearby_view.dart';

// ══════════════════════════════════════════════════════════════════════════
// 主 Tab 入口 — 三个 Tab 水平滑动
// ══════════════════════════════════════════════════════════════════════════

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
            VideoFeedView(
                controller: _getSharedFeedController(), tabIndex: _topTabIndex),
            // 精选 — 与关注共用视频流
            VideoFeedView(
                controller: _getSharedFeedController(), tabIndex: _topTabIndex),
            // 同城 — 瀑布流布局
            NearbyView(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    const titles = ['关注', '精选', '同城'];
    // 同城Tab使用深色背景
    final isCityTab = _topTabIndex == 2;

    return AppBar(
      backgroundColor: isCityTab ? Colors.black : Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
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
