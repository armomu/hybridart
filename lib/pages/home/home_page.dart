import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../controllers/lifecycle_controller.dart';
import 'widgets/lifecycle_logger_widget.dart';
import 'widgets/lifecycle_test_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化控制器
    final controller = Get.put(LifecycleController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('生命周期测试中心'),
        actions: [
          // 主题切换按钮
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => Get.toNamed(Routes.settings),
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed(Routes.settings),
          ),
        ],
      ),
      body: Obx(() => Column(
        children: [
          // 控制面板
          _buildControlPanel(controller),

          // 生命周期日志显示区域
          const Expanded(
            flex: 1,
            child: LifecycleLoggerWidget(),
          ),

          // 子组件显示区域
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: context.theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: controller.showChildWidget.value
                  ? LifecycleTestWidget(
                      key: ValueKey('test_${controller.showChildWidget.value}'),
                      title: controller.parentTitle.value,
                    )
                  : _buildEmptyState(),
            ),
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(Routes.lifecycleDetail),
        icon: const Icon(Icons.info_outline),
        label: const Text('详情'),
      ),
    );
  }

  Widget _buildControlPanel(LifecycleController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        children: [
          const Text(
            '父组件控制面板',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: controller.toggleChildWidget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Obx(() => Text(
                  controller.showChildWidget.value ? '销毁子组件' : '创建子组件',
                )),
              ),
              ElevatedButton(
                onPressed: controller.toggleParentTitle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('更新父组件参数'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => Text('当前父组件标题: ${controller.parentTitle.value}')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '子组件已销毁',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
