import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          // 扫一扫按钮
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: '扫一扫',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('扫一扫')),
              );
            },
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => Get.toNamed(Routes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserInfo(context),
            const SizedBox(height: 16),
            _buildFeatureGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '用户名称',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: 10086',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      // 第一项：直播
      _FeatureItem(
        icon: Icons.live_tv,
        label: '直播',
        onTap: () => Get.toNamed(Routes.live),
      ),
      // 第二项：生命周期 Demo
      _FeatureItem(
        icon: Icons.recycling,
        label: '生命周期',
        onTap: () => Get.toNamed(Routes.lifecycleDemo),
      ),
      // 第三项：充电桩管理
      _FeatureItem(
        icon: Icons.ev_station,
        label: '充电桩',
        onTap: () => Get.toNamed(Routes.charger),
      ),
      _FeatureItem(
        icon: Icons.favorite_border,
        label: '收藏',
        onTap: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('点击了 收藏'))),
      ),
      _FeatureItem(
        icon: Icons.history,
        label: '历史',
        onTap: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('点击了 历史'))),
      ),
      _FeatureItem(
        icon: Icons.bookmark_border,
        label: '书签',
        onTap: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('点击了 书签'))),
      ),
      _FeatureItem(
        icon: Icons.share_outlined,
        label: '分享',
        onTap: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('点击了 分享'))),
      ),
      _FeatureItem(
        icon: Icons.download_outlined,
        label: '下载',
        onTap: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('点击了 下载'))),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '常用功能',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              return _buildFeatureCell(context, features[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCell(BuildContext context, _FeatureItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
