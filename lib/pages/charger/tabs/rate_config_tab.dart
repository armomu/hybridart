import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../charger_controller.dart';

/// 费率配置 Tab
class RateConfigTab extends StatefulWidget {
  const RateConfigTab({super.key});

  @override
  State<RateConfigTab> createState() => _RateConfigTabState();
}

class _RateConfigTabState extends State<RateConfigTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ctrl = Get.find<ChargerController>();

  late final TextEditingController _peakCtrl;
  late final TextEditingController _flatCtrl;
  late final TextEditingController _valleyCtrl;
  late final TextEditingController _serviceCtrl;

  @override
  void initState() {
    super.initState();
    final cfg = ctrl.rateConfig.value;
    _peakCtrl = TextEditingController(text: cfg.peakRate);
    _flatCtrl = TextEditingController(text: cfg.flatRate);
    _valleyCtrl = TextEditingController(text: cfg.valleyRate);
    _serviceCtrl = TextEditingController(text: cfg.serviceRate);
  }

  @override
  void dispose() {
    _peakCtrl.dispose();
    _flatCtrl.dispose();
    _valleyCtrl.dispose();
    _serviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRate() async {
    final cfg = RateConfig(
      peakRate: _peakCtrl.text.trim(),
      flatRate: _flatCtrl.text.trim(),
      valleyRate: _valleyCtrl.text.trim(),
      serviceRate: _serviceCtrl.text.trim(),
    );
    final ok = await ctrl.sendRateConfig(cfg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '费率下发成功 ✅' : '下发失败，请重试'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 当前费率卡片 ──────────────────────────────────
          _buildSectionTitle('当前费率'),
          Obx(() {
            final cfg = ctrl.rateConfig.value;
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _rateRow('峰时电价', '¥ ${cfg.peakRate} /度',
                        Colors.red.shade400),
                    const Divider(height: 20),
                    _rateRow('平时电价', '¥ ${cfg.flatRate} /度',
                        Colors.orange.shade400),
                    const Divider(height: 20),
                    _rateRow('谷时电价', '¥ ${cfg.valleyRate} /度',
                        Colors.green.shade400),
                    const Divider(height: 20),
                    _rateRow('服务费', '¥ ${cfg.serviceRate} /度',
                        Colors.blue.shade400),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // ── 修改费率表单 ──────────────────────────────────
          _buildSectionTitle('修改费率'),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _rateField('峰时电价（元/度）', _peakCtrl, Colors.red.shade400),
                  const SizedBox(height: 12),
                  _rateField('平时电价（元/度）', _flatCtrl, Colors.orange.shade400),
                  const SizedBox(height: 12),
                  _rateField('谷时电价（元/度）', _valleyCtrl, Colors.green.shade400),
                  const SizedBox(height: 12),
                  _rateField('服务费（元/度）', _serviceCtrl, Colors.blue.shade400),
                  const SizedBox(height: 20),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: ctrl.isSendingRate.value ? null : _sendRate,
                          icon: ctrl.isSendingRate.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send),
                          label: Text(ctrl.isSendingRate.value ? '下发中...' : '下发费率'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '费率修改后立即生效，下一次充电将按新费率计费。',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _rateRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
            width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _rateField(
      String label, TextEditingController ctrl, Color accentColor) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '¥ ',
        suffixText: '/度',
        filled: true,
        fillColor: accentColor.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
    );
  }
}
