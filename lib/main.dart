import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'routes/app_routes.dart';
import 'routes/route_middleware.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==================== 系统方向 & 初始状态栏 ====================
  SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[DeviceOrientation.portraitUp]);

  // 初始化 GetStorage（用于本地存储）
  await GetStorage.init();

  // 注入主题控制器
  Get.put(ThemeController());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = Get.find<ThemeController>();

    // 注册系统主题切换监听
    WidgetsBinding.instance.addObserver(this);

    // 首次启动应用一次状态栏
    _applySystemUI();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 系统主题切换时回调（WidgetsBindingObserver）
  @override
  void didChangePlatformBrightness() {
    debugPrint('🔄 系统主题切换，重新应用状态栏样式');
    _applySystemUI();
  }

  /// 根据当前主题模式 + 系统亮度更新 SystemChrome
  void _applySystemUI() {
    final appMode = _themeController.appThemeMode;
    final systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    // 确定实际生效的背景亮度
    Brightness effectiveBgBrightness;
    if (appMode == AppThemeMode.system) {
      effectiveBgBrightness = systemBrightness;
    } else if (appMode == AppThemeMode.dark) {
      effectiveBgBrightness = Brightness.dark;
    } else {
      effectiveBgBrightness = Brightness.light;
    }

    // 背景亮 → 图标暗；背景暗 → 图标亮
    final iconBrightness = effectiveBgBrightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: iconBrightness,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 监听应用内主题切换，同步更新状态栏
      _applySystemUI();

      return GetMaterialApp(
        title: 'HybridArt - GetX 示例',
        debugShowCheckedModeBanner: false,

        // ==================== 主题配置 ====================
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeController.themeMode,

        // ==================== 全局 Builder ====================
        builder: (context, child) {
          return Stack(
            children: [
              // 底部安全区域着色：跟随主题 scaffoldBackgroundColor
              Positioned.directional(
                textDirection: TextDirection.ltr,
                bottom: 0,
                start: 0,
                end: 0,
                height: MediaQuery.of(context).padding.bottom,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              // 页面内容
              child ?? const SizedBox.shrink(),
            ],
          );
        },

        // ==================== 路由配置 ====================
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,

        // 默认过渡动画
        defaultTransition: Transition.native,

        // 路由中间件
        routingCallback: (routing) {
          debugPrint('📍 路由: ${routing?.current}');
        },

        // 国际化配置
        locale: const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),

        // 导航观察者
        navigatorObservers: [
          GetObserver((routing) {
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
      );
    });
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
