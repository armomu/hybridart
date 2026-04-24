import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ble_demo_controller.dart';
import 'tabs/send_data_tab.dart';
import 'tabs/ota_upgrade_tab.dart';

/// 蓝牙示例控制台——连接后的功能面板
class BleDemoDashboardPage extends StatelessWidget {
  const BleDemoDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BleDemoController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(
                ctrl.isConnected.value
                    ? (ctrl.connectedDevice.value?.platformName.isNotEmpty ==
                            true
                        ? ctrl.connectedDevice.value!.platformName
                        : '蓝牙设备')
                    : '蓝牙示例',
              )),
          bottom: const TabBar(
            tabs: [
              Tab(text: '发送数据'),
              Tab(text: 'OTA升级'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SendDataTab(),
            OtaUpgradeTab(),
          ],
        ),
      ),
    );
  }
}
