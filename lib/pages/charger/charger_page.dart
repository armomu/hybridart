import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import 'charger_controller.dart';
import 'charger_dashboard_page.dart';

/// 充电桩蓝牙主页——设备扫描与连接
class ChargerPage extends StatelessWidget {
  const ChargerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ChargerController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('充电桩管理'),
        centerTitle: true,
        actions: [
          Obx(() => ctrl.connectedDevice.value != null
              ? TextButton.icon(
                  onPressed: ctrl.disconnectDevice,
                  icon: const Icon(Icons.bluetooth_disabled, size: 18,
                      color: Colors.redAccent),
                  label: const Text('断开', style: TextStyle(color: Colors.redAccent)),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          // ── 顶部状态卡片 ──────────────────────────────────────
          _buildStatusCard(context, ctrl),
          const SizedBox(height: 8),

          // ── 扫描结果列表标题 ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('附近设备',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                Obx(() => ctrl.isScanning.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const SizedBox.shrink()),
              ],
            ),
          ),

          // ── 设备列表 ──────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.scanResults.isEmpty && !ctrl.isScanning.value) {
                return _buildEmptyHint(context);
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ctrl.scanResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final result = ctrl.scanResults[i];
                  return _buildDeviceCard(context, ctrl, result);
                },
              );
            }),
          ),
        ],
      ),

      // ── 扫描按钮 ───────────────────────────────────────────────
      floatingActionButton: Obx(() => FloatingActionButton.extended(
            onPressed:
                ctrl.isScanning.value ? ctrl.stopScan : ctrl.startScan,
            icon: Icon(
                ctrl.isScanning.value ? Icons.stop : Icons.bluetooth_searching),
            label: Text(ctrl.isScanning.value ? '停止扫描' : '开始扫描'),
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── 状态卡片 ─────────────────────────────────────────────────
  Widget _buildStatusCard(BuildContext context, ChargerController ctrl) {
    return Obx(() {
      final connected = ctrl.connectedDevice.value != null;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: connected
                ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
                : [const Color(0xFF757575), const Color(0xFFBDBDBD)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (connected ? Colors.blue : Colors.grey).withOpacity(0.3),
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
                        ? (ctrl.connectedDevice.value!.platformName.isNotEmpty
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
                        ? ctrl.connectedDevice.value!.remoteId.str
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
                  foregroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
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

  // ── 设备卡片 ─────────────────────────────────────────────────
  Widget _buildDeviceCard(BuildContext context, ChargerController ctrl,
      ScanResult result) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : '未知设备';
    final rssi = result.rssi;

    return Obx(() {
      final isConnecting = ctrl.isConnecting.value;
      final isConnected =
          ctrl.connectedDevice.value?.remoteId == result.device.remoteId;

      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.blue.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bluetooth,
              color: isConnected ? Colors.blue : Colors.grey[600],
            ),
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${result.device.remoteId.str}  RSSI: $rssi dBm',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          trailing: isConnected
              ? const Chip(
                  label: Text('已连接',
                      style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.zero,
                )
              : SizedBox(
                  width: 72,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: isConnecting
                        ? null
                        : () => ctrl.connectDevice(result.device),
                    child: isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('连接',
                            style: TextStyle(fontSize: 12)),
                  ),
                ),
        ),
      );
    });
  }

  // ── 空状态提示 ────────────────────────────────────────────────
  Widget _buildEmptyHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('点击下方按钮开始扫描',
              style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          const SizedBox(height: 8),
          Text('确保充电桩蓝牙处于广播状态',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
