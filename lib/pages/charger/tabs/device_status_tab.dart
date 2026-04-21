import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../charger_controller.dart';

/// 设备状态 Tab
class DeviceStatusTab extends StatelessWidget {
  const DeviceStatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ChargerController>();

    return Obx(() {
      return RefreshIndicator(
        onRefresh: ctrl.fetchStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 连接状态横幅 ──────────────────────────────────
            _buildConnectionBanner(ctrl),
            const SizedBox(height: 16),

            // ── 充电状态 ──────────────────────────────────────
            _buildSectionTitle('充电状态'),
            _buildStatusCard([
              _StatusItem(
                icon: Icons.bolt,
                iconColor: Colors.amber,
                label: '运行状态',
                value: ctrl.chargeState.value,
              ),
            ]),
            const SizedBox(height: 16),

            // ── 电气参数 ──────────────────────────────────────
            _buildSectionTitle('电气参数'),
            _buildStatusCard([
              _StatusItem(
                icon: Icons.electric_meter_outlined,
                iconColor: Colors.blue,
                label: '输出电压',
                value: ctrl.voltage.value,
              ),
              _StatusItem(
                icon: Icons.settings_input_component_outlined,
                iconColor: Colors.indigo,
                label: '输出电流',
                value: ctrl.current.value,
              ),
              _StatusItem(
                icon: Icons.power_outlined,
                iconColor: Colors.purple,
                label: '实时功率',
                value: ctrl.power.value,
              ),
            ]),
            const SizedBox(height: 16),

            // ── 环境参数 ──────────────────────────────────────
            _buildSectionTitle('环境参数'),
            _buildStatusCard([
              _StatusItem(
                icon: Icons.thermostat_outlined,
                iconColor: Colors.red,
                label: '模块温度',
                value: ctrl.temperature.value,
              ),
            ]),
            const SizedBox(height: 24),

            // ── 刷新按钮 ──────────────────────────────────────
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: ctrl.fetchStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新状态'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildConnectionBanner(ChargerController ctrl) {
    final connected = ctrl.connectedDevice.value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: connected ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: connected ? Colors.green.shade200 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.link : Icons.link_off,
            color: connected ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            connected ? '设备已连接' : '设备未连接',
            style: TextStyle(
              color: connected ? Colors.green[700] : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? Colors.green : Colors.grey,
              boxShadow: connected
                  ? [
                      BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 2)
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildStatusCard(List<_StatusItem> items) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                title: Text(item.label,
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
                trailing: Text(item.value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
              if (idx < items.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatusItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatusItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
}
