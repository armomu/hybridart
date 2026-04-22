# HybridArt

一款基于 Flutter + GetX 的多模块混合应用，集成了短视频、RTMP 直播、蓝牙充电桩管理（IoT）等功能。

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter (Dart SDK >= 3.3.4) |
| 状态管理 / 路由 / 依赖注入 | [GetX](https://pub.dev/packages/get) ^4.6.6 |
| 本地存储 | [GetStorage](https://pub.dev/packages/get_storage) ^2.1.1 |
| 短视频播放 | [video_player](https://pub.dev/packages/video_player) ^2.9.2 |
| 直播播放 (RTMP) | [flutter_vlc_player](https://pub.dev/packages/flutter_vlc_player) ^7.4.1 |
| 蓝牙 BLE | [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus) ^1.35.3 |
| 文件选择 (OTA) | [file_picker](https://pub.dev/packages/file_picker) ^8.0.5 |
| UI 风格 | Material 3 |

## 平台要求

- **Android**: minSdkVersion 21 (Android 5.0+，因 flutter_blue_plus 要求)
- **iOS**: 需在 Info.plist 中添加蓝牙权限声明（`NSBluetoothAlwaysUsageDescription`）
- **其他**: Web / Windows / macOS / Linux

## 项目结构

```
lib/
├── main.dart                              # 应用入口 (GetMaterialApp + 主题 + 路由)
├── controllers/
│   ├── lifecycle_controller.dart           # 生命周期演示控制器
│   └── test.dart                           # EventBus 事件总线工具类
├── routes/
│   ├── app_routes.dart                     # 路由定义 + 页面映射
│   └── route_middleware.dart               # 中间件 (鉴权/日志)
├── theme/
│   ├── app_theme.dart                      # 浅色/深色 Material 3 主题
│   └── theme_controller.dart               # 主题切换控制器
└── pages/
    ├── home/
    │   ├── home_page.dart                  # 首页 (底部 5 Tab 导航)
    │   ├── tabs/
    │   │   ├── home_tab.dart               # Tab: 首页 (占位)
    │   │   ├── short_video_tab.dart        # Tab: 短视频 (抖音风格)
    │   │   ├── message_tab.dart            # Tab: 消息 (占位)
    │   │   └── profile_tab.dart            # Tab: 我的 (功能入口网格)
    │   └── widgets/
    │       ├── lifecycle_logger_widget.dart # 生命周期日志面板
    │       └── lifecycle_test_widget.dart   # 生命周期测试子组件
    ├── live/
    │   └── live_page.dart                  # 直播页 (RTMP + VLC)
    ├── charger/
    │   ├── charger_page.dart               # 充电桩蓝牙扫描/连接
    │   ├── charger_dashboard_page.dart     # 充电桩管理控制台 (5 Tab)
    │   ├── charger_controller.dart         # 充电桩蓝牙控制器 (核心业务逻辑)
    │   └── tabs/
    │       ├── charge_records_tab.dart     # 充电记录
    │       ├── rate_config_tab.dart        # 费率配置
    │       ├── device_status_tab.dart      # 设备状态
    │       ├── version_info_tab.dart       # 版本信息
    │       └── ota_upgrade_tab.dart        # OTA 升级
    ├── lifecycle/
    │   ├── lifecycle_demo_page.dart        # 生命周期 Demo
    │   └── lifecycle_detail_page.dart      # 生命周期详情文档
    └── settings/
        └── settings_page.dart              # 设置页
```

## 功能模块

### 短视频

- 抖音风格竖向滑动（PageView），上下切换视频
- 顶部三个子分类：**关注 / 精选 / 同城**（水平滑动切换）
- 关注/精选共享同一视频流控制器，支持懒加载与可见性检测
- 同城为左右双列图文瀑布流布局
- 右侧操作栏：关注、点赞、评论、收藏、分享
- 底部用户名 + 视频描述

### 直播

- 基于 `flutter_vlc_player` 播放 RTMP 直播流
- 硬件加速 + 网络缓存参数配置
- 播放状态管理：缓冲 / 播放 / 错误处理 + 重连
- 顶部主播信息 + 关注按钮 + 在线人数
- 右侧操作栏：分享 / 点赞 / 声音
- 下方互动区 Tab：聊天（可发送消息）、投票（占位）、赛况（占位）

### 蓝牙充电桩管理 (IoT)

- BLE 设备扫描、连接、断开（基于 flutter_blue_plus）
- **Mock/真实双模式**：无需真实蓝牙设备即可预览全部功能
- 管理控制台 5 个 Tab：

| Tab | 功能 |
|-----|------|
| 充电记录 | 查询历史记录 + 汇总统计（次数/电量/费用） |
| 费率配置 | 查看/修改峰/平/谷/服务费率 |
| 设备状态 | 实时状态（充电状态/电压/电流/功率/温度） |
| 版本信息 | 软硬件版本 + MAC + 连接状态 |
| OTA 升级 | 选择升级包 / 分包传输 / 进度条 / 校验 / 日志 |

- BLE 协议帧格式预留：`[0xAA, cmd, data..., 0xBB]`
- 服务发现 + 通知特征订阅

### 其他

- **主题系统**：Material 3 浅色/深色双主题，通过 GetStorage 持久化
- **Tab 懒加载**：首页底部 Tab 采用 Offstage + 懒创建策略
- **生命周期 Demo**：可视化 Flutter Widget 生命周期，终端风格日志面板
- **GetX 特性演示**：路由跳转、Snackbar、Dialog、BottomSheet

## 快速开始

### 环境准备

1. 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.3.4)
2. 确保已配置 Android / iOS 开发环境

### 安装依赖

```bash
flutter pub get
```

### 运行项目

```bash
# Android
flutter run

# iOS (需 macOS + Xcode)
flutter run -d ios

# 指定设备
flutter run -d <device_id>
```

### 构建 Release

```bash
# Android APK
flutter build apk

# iOS (需 Xcode 签名配置)
flutter build ios
```

## 架构设计

```
┌─────────────────────────────────────────────────┐
│                   main.dart                      │
│            (GetMaterialApp + 主题 + 路由)         │
├─────────────────────────────────────────────────┤
│  routes/          │  controllers/   │  theme/    │
│  app_routes       │  lifecycle_ctrl │  app_theme │
│  middleware       │  event_bus      │  theme_ctrl│
├─────────────────────────────────────────────────┤
│  pages/                                       │
│  ┌──────────┐ ┌──────────┐ ┌───────────────┐  │
│  │   home   │ │  live    │ │   charger     │  │
│  │ ┌──────┐ │ │ RTMP/VLC │ │ BLE 扫描/连接 │  │
│  │ │video │ │ │ 聊天互动  │ │ 充电记录      │  │
│  │ │feed  │ │ │          │ │ 费率下发      │  │
│  │ │同城  │ │ │          │ │ 设备状态      │  │
│  │ └──────┘ │ │          │ │ OTA 升级      │  │
│  │ profile  │ │          │ │ 版本信息      │  │
│  │ settings │ │          │ │               │  │
│  └──────────┘ └──────────┘ └───────────────┘  │
│  ┌──────────────────────┐                      │
│  │ lifecycle (Demo/Doc) │                      │
│  └──────────────────────┘                      │
└─────────────────────────────────────────────────┘
```

**关键设计特点**：

1. **GetX 全家桶**：状态管理 + 路由 + 依赖注入，无 BuildContext 导航
2. **BLE IoT 实战**：完整的蓝牙充电桩管理（扫描/连接/数据交互/OTA）
3. **Mock/真实双模式**：充电桩功能支持模拟模式，无硬件也可预览
4. **Tab 懒加载**：首页底部 Tab 采用 Offstage + 懒创建策略
5. **Material 3 主题**：浅色/深色双主题，通过 GetStorage 持久化
6. **视频双引擎**：短视频（video_player）+ 直播（VLC/RTMP）

## 待完成

- [ ] 首页 Tab、消息 Tab 内容开发
- [ ] 直播投票、赛况互动功能
- [ ] iOS Info.plist 蓝牙权限声明
- [ ] 单元测试编写（当前测试文件为脚手架默认内容）
- [ ] Release 签名配置
- [ ] 应用 ID 替换（当前为 `com.example.hybridart`）

## License

Private project.
