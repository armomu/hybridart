import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'charger_controller.dart';
import 'tabs/charge_records_tab.dart';
import 'tabs/rate_config_tab.dart';
import 'tabs/device_status_tab.dart';
import 'tabs/version_info_tab.dart';
import 'tabs/ota_upgrade_tab.dart';

/// 充电桩管理控制台——连接后的功能面板
class ChargerDashboardPage extends StatelessWidget {
  const ChargerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ChargerController>();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(
                ctrl.isConnected.value
                    ? (ctrl.connectedDevice.value?.platformName.isNotEmpty ==
                            true
                        ? ctrl.connectedDevice.value!.platformName
                        : '充电桩设备')
                    : '充电桩控制台',
              )),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.history, size: 20), text: '充电记录'),
              Tab(
                  icon: Icon(Icons.price_change_outlined, size: 20),
                  text: '费率配置'),
              Tab(
                  icon: Icon(Icons.monitor_heart_outlined, size: 20),
                  text: '设备状态'),
              Tab(icon: Icon(Icons.info_outline, size: 20), text: '版本信息'),
              Tab(icon: Icon(Icons.system_update_alt, size: 20), text: 'OTA升级'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ChargeRecordsTab(),
            RateConfigTab(),
            DeviceStatusTab(),
            VersionInfoTab(),
            OtaUpgradeTab(),
          ],
        ),
      ),
    );
  }
}
