import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../charger_controller.dart';

/// 版本信息 Tab
class VersionInfoTab extends StatefulWidget {
  const VersionInfoTab({super.key});

  @override
  State<VersionInfoTab> createState() => _VersionInfoTabState();
}

class _VersionInfoTabState extends State<VersionInfoTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ctrl = Get.find<ChargerController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.fetchVersion();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 设备图示卡片 ──────────────────────────────────
            _buildDeviceCard(),
            const SizedBox(height: 20),

            // ── 版本信息列表 ──────────────────────────────────
            _buildSectionTitle('软硬件版本'),
            _buildInfoCard([
              _InfoRow(label: '固件版本', value: ctrl.firmwareVersion.value,
                  icon: Icons.memory, iconColor: Colors.blue),
              _InfoRow(label: '硬件版本', value: ctrl.hardwareVersion.value,
                  icon: Icons.developer_board, iconColor: Colors.teal),
              _InfoRow(label: '设备型号', value: ctrl.deviceModel.value,
                  icon: Icons.ev_station, iconColor: Colors.indigo),
            ]),
            const SizedBox(height: 16),

            _buildSectionTitle('设备标识'),
            _buildInfoCard([
              _InfoRow(
                label: '设备 MAC',
                value: ctrl.isConnected.value
                    ? (ctrl.connectedDevice.value?.remoteId.str ?? 'Mock')
                    : '未连接',
                icon: Icons.router_outlined,
                iconColor: Colors.purple,
              ),
              _InfoRow(
                label: '连接状态',
                value: ctrl.deviceStatus.value,
                icon: Icons.bluetooth_connected,
                iconColor: Colors.lightBlue,
              ),
            ]),
            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: ctrl.fetchVersion,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新版本信息'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.ev_station, size: 60, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      ctrl.deviceModel.value == '—'
                          ? '充电桩设备'
                          : ctrl.deviceModel.value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    )),
                const SizedBox(height: 6),
                Obx(() => Text(
                      '固件: ${ctrl.firmwareVersion.value}  |  硬件: ${ctrl.hardwareVersion.value}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 12),
                    )),
              ],
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
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: row.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(row.icon, color: row.iconColor, size: 18),
                ),
                title: Text(row.label,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54)),
                trailing: Text(row.value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              if (idx < rows.length - 1)
                const Divider(height: 1, indent: 68),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });
}
