import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import 'charger_controller.dart';
import 'charger_dashboard_page.dart';

/// 充电桩蓝牙主页——设备扫描与连接
class ChargerPage extends StatefulWidget {
  const ChargerPage({super.key});

  @override
  State<ChargerPage> createState() => _ChargerPageState();
}

class _ChargerPageState extends State<ChargerPage> {
  // 在 State 中注册 Controller，避免 Obx 在回调内触发 GetX 作用域警告
  final ctrl = Get.put(ChargerController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('充电桩管理'),
        centerTitle: true,
        actions: [
          // 模拟测试开关
          Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '模拟',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          ctrl.isMock.value ? Colors.white70 : Colors.white38,
                    ),
                  ),
                  Switch(
                    value: ctrl.isMock.value,
                    onChanged: (value) => ctrl.isMock.value = value,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.grey,
                  ),
                ],
              )),
          // 断开按钮：GetBuilder 不依赖 Obx
          GetBuilder<ChargerController>(
            builder: (c) => c.isConnected.value
                ? TextButton.icon(
                    onPressed: c.disconnectDevice,
                    icon: Icon(Icons.bluetooth_disabled,
                        size: 18, color: colorScheme.error),
                    label:
                        Text('断开', style: TextStyle(color: colorScheme.error)),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 顶部状态卡片 ──────────────────────────────────────
          _StatusCard(ctrl: ctrl),
          const SizedBox(height: 8),

          // ── 扫描结果列表标题（Mock 模式下隐藏）────────────────
          Obx(() => !ctrl.isMock.value
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('附近设备',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                      const Spacer(),
                      ctrl.isScanning.value
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ))
                          : const SizedBox.shrink(),
                    ],
                  ),
                )
              : const SizedBox.shrink()),

          // ── 设备列表 ──────────────────────────────────────────
          Expanded(
            child: Obx(() => ctrl.isMock.value
                ? _MockDeviceArea(ctrl: ctrl)
                : _ScanResultsList(ctrl: ctrl)),
          ),
        ],
      ),

      // ── 扫描按钮（Mock 模式下隐藏）───────────────────────────
      floatingActionButton: Obx(() => !ctrl.isMock.value
          ? FloatingActionButton.extended(
              onPressed: ctrl.isScanning.value ? ctrl.stopScan : ctrl.startScan,
              icon: Icon(ctrl.isScanning.value
                  ? Icons.stop
                  : Icons.bluetooth_searching),
              label: Text(ctrl.isScanning.value ? '停止扫描' : '开始扫描'),
            )
          : const SizedBox.shrink()),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── 状态卡片（独立 StatefulWidget，避免 Obx 在回调内触发警告）───
class _StatusCard extends StatelessWidget {
  final ChargerController ctrl;
  const _StatusCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final connected = ctrl.isConnected.value;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: connected
                ? [colorScheme.primary, colorScheme.secondary]
                : [colorScheme.outline, colorScheme.outlineVariant],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (connected ? colorScheme.primary : colorScheme.outline)
                  .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                connected ? Icons.ev_station : Icons.ev_station_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text(
                        ctrl.isConnected.value
                            ? (ctrl.connectedDevice.value?.platformName
                                        .isNotEmpty ==
                                    true
                                ? ctrl.connectedDevice.value!.platformName
                                : '充电桩设备')
                            : '未连接任何设备',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      )),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        ctrl.isConnected.value
                            ? (ctrl.connectedDevice.value?.remoteId.str ??
                                'Mock Device')
                            : '请扫描并选择附近充电桩',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12),
                      )),
                ],
              ),
            ),
            if (connected)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => Get.to(() => const ChargerDashboardPage()),
                child: const Text('管理',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      );
    });
  }
}

// ── Mock 设备区域 ─────────────────────────────────────────────
class _MockDeviceArea extends StatelessWidget {
  final ChargerController ctrl;
  const _MockDeviceArea({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            color: colorScheme.surfaceVariant,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.ev_station,
                        size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EV-CHARGER-7KW',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MAC: AA:BB:CC:DD:EE:FF',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '模拟设备 · 无需蓝牙',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: ctrl.isConnecting.value
                              ? null
                              : () async {
                                  await ctrl.connectMockDevice();
                                  if (ctrl.isConnected.value) {
                                    Get.to(() => const ChargerDashboardPage());
                                  }
                                },
                          child: ctrl.isConnecting.value
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary))
                              : const Text('连接模拟设备',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primaryContainer),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '当前为 Mock 模式，所有蓝牙操作已模拟，可完整预览充电记录、费率下发、状态查询、版本信息、OTA 升级全部流程。\n\n关闭 AppBar 上的模拟开关后即可切换为真实模式。',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── 真实扫描结果列表（独立 StatelessWidget，避免 Obx 在 ListView.itemBuilder 内触发警告）───
class _ScanResultsList extends StatelessWidget {
  final ChargerController ctrl;
  const _ScanResultsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      if (ctrl.scanResults.isEmpty && !ctrl.isScanning.value) {
        return _buildEmptyHint(colorScheme, theme);
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ctrl.scanResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final result = ctrl.scanResults[i];
          return _DeviceCard(result: result);
        },
      );
    });
  }

  Widget _buildEmptyHint(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching,
              size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('点击下方按钮开始扫描',
              style:
                  TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15)),
          const SizedBox(height: 8),
          Text('确保充电桩蓝牙处于广播状态',
              style: TextStyle(color: colorScheme.outline, fontSize: 13)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── 单个设备卡片（独立 StatelessWidget，Obx 只在自己的 build 内）──
class _DeviceCard extends StatelessWidget {
  final ScanResult result;
  const _DeviceCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ctrl = Get.find<ChargerController>();
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : '未知设备';
    final rssi = result.rssi;

    return Obx(() {
      final isConnecting = ctrl.isConnecting.value;
      final isConnected = ctrl.isConnected.value &&
          ctrl.connectedDevice.value?.remoteId == result.device.remoteId;

      return Card(
        elevation: 1,
        color: colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isConnected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bluetooth,
              color: isConnected ? colorScheme.primary : colorScheme.outline,
            ),
          ),
          title: Text(name,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          subtitle: Text(
            '${result.device.remoteId.str}  RSSI: $rssi dBm',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          trailing: isConnected
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('已连接',
                      style: TextStyle(fontSize: 11, color: Colors.white)),
                )
              : SizedBox(
                  width: 72,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: isConnecting
                        ? null
                        : () => ctrl.connectDevice(result.device),
                    child: isConnecting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: colorScheme.primary))
                        : const Text('连接', style: TextStyle(fontSize: 12)),
                  ),
                ),
        ),
      );
    });
  }
}
