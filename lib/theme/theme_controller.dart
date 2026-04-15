import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 主题控制器 - 管理应用主题状态
class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  final _box = GetStorage();
  final _themeKey = 'isDarkMode';

  // 使用 Rx 变量响应式管理主题状态
  final _isDarkMode = false.obs;

  /// 当前是否为深色模式
  bool get isDarkMode => _isDarkMode.value;

  /// 当前主题模式
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    // 从本地存储读取主题设置
    _isDarkMode.value = _box.read(_themeKey) ?? false;
  }

  /// 切换主题
  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _box.write(_themeKey, _isDarkMode.value);
    Get.changeThemeMode(themeMode);
    update();
  }

  /// 设置为浅色模式
  void setLightMode() {
    _isDarkMode.value = false;
    _box.write(_themeKey, false);
    Get.changeThemeMode(ThemeMode.light);
    update();
  }

  /// 设置为深色模式
  void setDarkMode() {
    _isDarkMode.value = true;
    _box.write(_themeKey, true);
    Get.changeThemeMode(ThemeMode.dark);
    update();
  }

  /// 跟随系统主题
  void setSystemMode() {
    _isDarkMode.value = false;
    _box.remove(_themeKey);
    Get.changeThemeMode(ThemeMode.system);
    update();
  }
}
