import 'package:get/get.dart';
import '../pages/home/home_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/lifecycle/lifecycle_detail_page.dart';
import '../pages/lifecycle/lifecycle_demo_page.dart';
import '../pages/live/live_page.dart';
import '../pages/charger/charger_page.dart';

/// 路由名称常量
abstract class Routes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String lifecycleDetail = '/lifecycle-detail';
  static const String lifecycleDemo = '/lifecycle-demo';
  static const String live = '/live';
  static const String charger = '/charger';
}

/// 路由配置
class AppPages {
  static const String initial = Routes.home;

  static final List<GetPage> routes = [
    GetPage(
      name: Routes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.lifecycleDetail,
      page: () => const LifecycleDetailPage(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: Routes.lifecycleDemo,
      page: () => const LifecycleDemoPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.live,
      page: () => const LivePage(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.charger,
      page: () => const ChargerPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
  ];
}

/// Home 页面绑定
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // 这里可以注入 Home 页面需要的 Controller
    // Get.lazyPut<HomeController>(() => HomeController());
  }
}
