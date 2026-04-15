import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 路由中间件示例 - 可用于登录验证、权限检查等
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // 示例：检查是否需要登录
    // final isLoggedIn = Get.find<AuthController>().isLoggedIn;
    // if (!isLoggedIn && route != Routes.login) {
    //   return const RouteSettings(name: Routes.login);
    // }
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    debugPrint('🚀 页面被调用: ${page?.name}');
    return page;
  }

  @override
  List<Bindings>? onBindingsStart(List<Bindings>? bindings) {
    debugPrint('🔗 绑定开始: ${bindings?.length}');
    return bindings;
  }

  @override
  Widget onPageBuilt(Widget page) {
    debugPrint('🏗️ 页面构建完成');
    return page;
  }

  @override
  void onPageDispose() {
    debugPrint('🗑️ 页面已销毁');
  }
}

/// 日志中间件 - 记录路由跳转
class LoggingMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    debugPrint('📍 路由跳转: $route');
    return null;
  }
}
