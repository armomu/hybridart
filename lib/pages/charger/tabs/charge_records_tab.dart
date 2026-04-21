import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../charger_controller.dart';

/// 充电记录 Tab
class ChargeRecordsTab extends StatefulWidget {
  const ChargeRecordsTab({super.key});

  @override
  State<ChargeRecordsTab> createState() => _ChargeRecordsTabState();
}

class _ChargeRecordsTabState extends State<ChargeRecordsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ctrl = Get.find<ChargerController>();

  @override
  void initState() {
    super.initState();
    // 进入Tab自动拉取一次
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.fetchChargeRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      if (ctrl.isLoadingRecords.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (ctrl.chargeRecords.isEmpty) {
        return _buildEmpty();
      }
      return RefreshIndicator(
        onRefresh: ctrl.fetchChargeRecords,
        child: Column(
          children: [
            _buildSummaryBar(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: ctrl.chargeRecords.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) =>
                    _buildRecordCard(ctrl.chargeRecords[i]),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryBar() {
    final records = ctrl.chargeRecords;
    final totalEnergy =
        records.fold<double>(0, (sum, r) => sum + r.energy);
    final totalFee = records.fold<double>(0, (sum, r) => sum + r.fee);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _summaryItem('共 ${records.length} 条', '充电次数'),
          _summaryItem('${totalEnergy.toStringAsFixed(1)} 度', '累计电量'),
          _summaryItem('¥ ${totalFee.toStringAsFixed(2)}', '累计费用'),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRecordCard(ChargeRecord record) {
    final isNormal = record.status == '正常完成';
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    (isNormal ? Colors.green : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isNormal ? Icons.check_circle_outline : Icons.warning_amber,
                color: isNormal ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(record.id,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isNormal
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(record.status,
                            style: TextStyle(
                                fontSize: 10,
                                color: isNormal ? Colors.green : Colors.orange)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.startTime}  →  ${record.endTime}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${record.energy.toStringAsFixed(1)} 度',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 14)),
                Text('¥ ${record.fee.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('暂无充电记录',
              style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: ctrl.fetchChargeRecords,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('刷新'),
          ),
        ],
      ),
    );
  }
}
