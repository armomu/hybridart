import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import 'tabs/short_video_tab.dart';
import 'tabs/message_tab.dart';
import 'tabs/profile_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 当前激活的 navIndex（0=首页, 1=短视频, 2=+号, 3=消息, 4=我的）
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomeTab(),
    ShortVideoTab(),
    MessageTab(),
    ProfileTab(),
  ];

  /// navIndex → 页面索引（+号占位不对应页面，跳过）
  int _navIndexToPageIndex(int navIndex) {
    if (navIndex < 2) return navIndex;
    return navIndex - 1;
  }

  void _onTabTapped(int navIndex) {
    if (navIndex == 2) {
      _onPlusPressed();
      return;
    }
    setState(() {
      _currentIndex = navIndex;
    });
  }

  void _onPlusPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('点击了 + 按钮'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndexToPageIndex(_currentIndex),
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '首页',
                navIndex: 0,
              ),
              _buildNavItem(
                context,
                icon: Icons.play_circle_outline,
                activeIcon: Icons.play_circle,
                label: '短视频',
                navIndex: 1,
              ),
              // 中间 + 号按钮
              _buildPlusItem(context),
              _buildNavItem(
                context,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: '消息',
                navIndex: 3,
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '我的',
                navIndex: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int navIndex,
  }) {
    final bool isActive = _currentIndex == navIndex;
    final color =
        isActive ? Theme.of(context).colorScheme.primary : Colors.grey[600]!;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(navIndex),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlusItem(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(2),
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
