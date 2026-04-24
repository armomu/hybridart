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
  final ctrl = Get.put(ChargerController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('充电桩管理'),
        actions: [
          // 断开按钮
          Obx(() => ctrl.isConnected.value
              ? TextButton.icon(
                  onPressed: ctrl.disconnectDevice,
                  icon: Icon(Icons.bluetooth_disabled,
                      size: 18, color: colorScheme.error),
                  label: Text('断开', style: TextStyle(color: colorScheme.error)),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          // ── 顶部状态卡片 ──────────────────────────────────────
          _StatusCard(ctrl: ctrl),
          const SizedBox(height: 8),

          // ── 扫描结果列表标题 ──────────────────────────────────
          Obx(() => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('附近设备',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const Spacer(),
                    if (ctrl.isScanning.value)
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          )),
                  ],
                ),
              )),

          // ── 设备列表 ──────────────────────────────────────────
          Expanded(child: _ScanResultsList(ctrl: ctrl)),
        ],
      ),

      // ── 扫描按钮 ──────────────────────────────────────────────
      floatingActionButton: Obx(() => FloatingActionButton.extended(
            onPressed: ctrl.isScanning.value ? ctrl.stopScan : ctrl.startScan,
            icon: Icon(
                ctrl.isScanning.value ? Icons.stop : Icons.bluetooth_searching),
            label: Text(ctrl.isScanning.value ? '停止扫描' : '开始扫描'),
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── 状态卡片 ─────────────────────────────────────────────────
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
                  Text(
                    connected
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    connected
                        ? (ctrl.connectedDevice.value?.remoteId.str ?? '—')
                        : '请扫描并选择附近充电桩',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
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

// ── 扫描结果列表 ──────────────────────────────────────────────
class _ScanResultsList extends StatelessWidget {
  final ChargerController ctrl;
  const _ScanResultsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      if (ctrl.scanResults.isEmpty && !ctrl.isScanning.value) {
        return _buildEmptyHint(colorScheme);
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ctrl.scanResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          return _DeviceCard(result: ctrl.scanResults[i]);
        },
      );
    });
  }

  Widget _buildEmptyHint(ColorScheme colorScheme) {
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

// ── 单个设备卡片 ──────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final ScanResult result;
  const _DeviceCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ctrl = Get.find<ChargerController>();
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : '未知设备';
    final rssi = result.rssi;

    return Obx(() {
      final isThisDeviceConnecting = ctrl.isConnecting.value &&
          ctrl.connectingDeviceId.value == result.device.remoteId.str;
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
                    onPressed: isThisDeviceConnecting
                        ? null
                        : () => ctrl.connectDevice(result.device),
                    child: isThisDeviceConnecting
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
