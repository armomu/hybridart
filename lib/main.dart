import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 GetStorage（用于本地存储）
  await GetStorage.init();

  // 注入主题控制器
  Get.put(ThemeController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
          title: 'HybridArt - GetX 示例',
          debugShowCheckedModeBanner: false,

          // ==================== 主题配置 ====================
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,

          // ==================== 路由配置 ====================
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,

          // 默认过渡动画
          defaultTransition: Transition.native,

          // 路由中间件
          routingCallback: (routing) {
            // 可以在这里添加全局路由监听
            // debugPrint('📍 路由: ${routing?.current}');
          },

          // 国际化配置（可选）
          locale: const Locale('zh', 'CN'),
          fallbackLocale: const Locale('en', 'US'),

          // 导航观察者
          navigatorObservers: [
            GetObserver((routing) {
              // 路由变化监听
              if (routing?.current == '/settings') {
                debugPrint('🔧 进入设置页面');
              }
            }),
          ],

          // 未知路由
          unknownRoute: GetPage(
            name: '/not-found',
            page: () => const NotFoundPage(),
          ),
        ));
  }
}

/// 404 页面
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '页面不存在或已被移除',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed(Routes.home),
              icon: const Icon(Icons.home),
              label: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
