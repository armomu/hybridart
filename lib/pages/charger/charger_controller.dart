import 'dart:async';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

/// 充电记录数据模型
class ChargeRecord {
  final String id;
  final String startTime;
  final String endTime;
  final double energy; // 度
  final double fee; // 元
  final String status;

  const ChargeRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.energy,
    required this.fee,
    required this.status,
  });

  factory ChargeRecord.fromMock(int index) {
    final day = (index % 28) + 1;
    final hour = (index * 3) % 24;
    final minute = (index * 7) % 60;
    return ChargeRecord(
      id: 'REC${1000 + index}',
      startTime:
          '2026-04-${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      endTime:
          '2026-04-${day.toString().padLeft(2, '0')} ${(hour + 2).toString().padLeft(2, '0')}:${(minute + 15) % 60}',
      energy: 12.5 + index * 1.8,
      fee: (12.5 + index * 1.8) * 0.85,
      status: index % 5 == 0 ? '异常中断' : '正常完成',
    );
  }
}

/// 费率数据模型
class RateConfig {
  String peakRate; // 峰时电价
  String flatRate; // 平时电价
  String valleyRate; // 谷时电价
  String serviceRate; // 服务费

  RateConfig({
    this.peakRate = '1.20',
    this.flatRate = '0.85',
    this.valleyRate = '0.40',
    this.serviceRate = '0.30',
  });
}

/// OTA 升级状态
enum OtaState { idle, selecting, uploading, verifying, success, failed }

/// 充电桩蓝牙控制器
/// [isMock=true] 时所有蓝牙操作走模拟，无需真实设备即可预览全流程。
class ChargerController extends GetxController {
  // ── Mock 开关 ──────────────────────────────────────────────────
  /// 设为 true 时跳过真实蓝牙，使用模拟数据预览全流程
  /// 使用 RxBool 以支持 UI 切换开关
  final isMock = true.obs;

  // ── 扫描 & 连接 ───────────────────────────────────────────────
  final isScanning = false.obs;
  final scanResults = <ScanResult>[].obs;
  final connectedDevice = Rxn<BluetoothDevice>();
  final connectionState = BluetoothConnectionState.disconnected.obs;
  final isConnecting = false.obs;
  /// 统一连接状态标记（Mock/真实模式均使用此字段驱动 UI）
  final isConnected = false.obs;

  // ── 设备信息 ───────────────────────────────────────────────────
  final deviceStatus = '未连接'.obs;
  final firmwareVersion = '—'.obs;
  final hardwareVersion = '—'.obs;
  final deviceModel = '—'.obs;
  final chargeState = '—'.obs;
  final voltage = '—'.obs;
  final current = '—'.obs;
  final power = '—'.obs;
  final temperature = '—'.obs;

  // ── 充电记录 ───────────────────────────────────────────────────
  final chargeRecords = <ChargeRecord>[].obs;
  final isLoadingRecords = false.obs;

  // ── 费率配置 ───────────────────────────────────────────────────
  final rateConfig = RateConfig().obs;
  final isSendingRate = false.obs;

  // ── OTA ────────────────────────────────────────────────────────
  final otaState = OtaState.idle.obs;
  final otaProgress = 0.0.obs;
  final otaFilePath = ''.obs;
  final otaFileName = ''.obs;
  final otaLog = <String>[].obs;

  // ── 内部 ───────────────────────────────────────────────────────
  StreamSubscription? _scanSub;
  StreamSubscription? _connStateSub;
  StreamSubscription? _notifySub;

  // ─────────────────────────────────────────────────────────────
  //  扫描（Mock：直接成功，跳过真实 BLE 扫描）
  // ─────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    if (isScanning.value) return;
    scanResults.clear();
    isScanning.value = true;

    if (isMock.value) {
      // 模拟扫描 2 秒延迟
      await Future.delayed(const Duration(seconds: 2));
      isScanning.value = false;
      return;
    }

    // 真实扫描
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      Get.snackbar('蓝牙未开启', '请先开启手机蓝牙',
          snackPosition: SnackPosition.BOTTOM);
      isScanning.value = false;
      return;
    }

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      scanResults.assignAll(results);
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    isScanning.value = false;
  }

  Future<void> stopScan() async {
    if (isMock.value) {
      isScanning.value = false;
      return;
    }
    await FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  // ─────────────────────────────────────────────────────────────
  //  连接 / 断开（Mock：跳过真实 BLE，直接成功）
  // ─────────────────────────────────────────────────────────────

  /// 连接模拟设备（UI 点击设备卡片时调用）
  Future<void> connectMockDevice() async {
    await connectDevice(null);
  }

  Future<void> connectDevice(BluetoothDevice? device) async {
    if (isConnecting.value) return;
    isConnecting.value = true;

    if (isMock.value) {
      // 模拟连接 1 秒延迟
      await Future.delayed(const Duration(seconds: 1));
      connectedDevice.value = device;
      isConnected.value = true;
      connectionState.value = BluetoothConnectionState.connected;
      deviceStatus.value = '已连接（模拟）';
      isConnecting.value = false;
      await _mockFetchStatus();
      return;
    }

    // 真实连接
    try {
      await device!.connect(timeout: const Duration(seconds: 10));
      connectedDevice.value = device;
      isConnected.value = true;

      _connStateSub?.cancel();
      _connStateSub = device.connectionState.listen((state) {
        connectionState.value = state;
        if (state == BluetoothConnectionState.disconnected) {
          _onDisconnected();
        }
      });

      await _discoverServices(device);
      deviceStatus.value = '已连接';
      await _mockFetchStatus();
    } catch (e) {
      Get.snackbar('连接失败', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> disconnectDevice() async {
    if (isMock.value) {
      _onDisconnected();
      return;
    }
    await connectedDevice.value?.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    connectedDevice.value = null;
    isConnected.value = false;
    connectionState.value = BluetoothConnectionState.disconnected;
    deviceStatus.value = '已断开';
    chargeState.value = '—';
    voltage.value = '—';
    current.value = '—';
    power.value = '—';
    temperature.value = '—';
    firmwareVersion.value = '—';
    hardwareVersion.value = '—';
    deviceModel.value = '—';
  }

  // ─────────────────────────────────────────────────────────────
  //  服务发现 & 特征订阅（真实 BLE 连接时调用）
  // ─────────────────────────────────────────────────────────────

  /// 发现服务并订阅通知特征
  /// TODO: 替换 _serviceUUID / _writeCharUUID / _notifyCharUUID 为实际设备 UUID
  Future<void> _discoverServices(BluetoothDevice device) async {
    const _serviceUUID = '0000FFE0-0000-1000-8000-00805F9B34FB';
    const _writeCharUUID = '0000FFE1-0000-1000-8000-00805F9B34FB';
    const _notifyCharUUID = '0000FFE1-0000-1000-8000-00805F9B34FB';

    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid.str.toUpperCase() !=
          _serviceUUID.toUpperCase()) continue;

      for (final char in service.characteristics) {
        if (char.uuid.str.toUpperCase() == _writeCharUUID.toUpperCase()) {
          // 写入特征
        }
        if (char.uuid.str.toUpperCase() == _notifyCharUUID.toUpperCase()) {
          await char.setNotifyValue(true);
          _notifySub?.cancel();
          _notifySub = char.lastValueStream.listen((value) {
            _handleNotification(value);
          });
        }
      }
    }
  }

  /// 处理设备主动上报的通知数据
  void _handleNotification(List<int> data) {
    // TODO: 按实际协议解析 data
    // 示例：data[0] 为帧类型，data[1..n] 为内容
  }

  // ─────────────────────────────────────────────────────────────
  //  发送命令（Mock：直接返回 true）
  // ─────────────────────────────────────────────────────────────

  Future<bool> _sendCommand(List<int> cmd) async {
    if (isMock.value) return true;
    // 真实写入 ...
    return true;
  }

  // ─────────────────────────────────────────────────────────────
  //  充电记录
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchChargeRecords() async {
    isLoadingRecords.value = true;
    await _sendCommand([0xAA, 0x01, 0x00, 0xBB]);
    await Future.delayed(const Duration(milliseconds: 800));
    chargeRecords.assignAll(
      List.generate(10, (i) => ChargeRecord.fromMock(i)),
    );
    isLoadingRecords.value = false;
  }

  // ─────────────────────────────────────────────────────────────
  //  下发费率
  // ─────────────────────────────────────────────────────────────

  Future<bool> sendRateConfig(RateConfig cfg) async {
    isSendingRate.value = true;
    final peak = (double.tryParse(cfg.peakRate) ?? 0) * 100;
    final flat = (double.tryParse(cfg.flatRate) ?? 0) * 100;
    final valley = (double.tryParse(cfg.valleyRate) ?? 0) * 100;
    final service = (double.tryParse(cfg.serviceRate) ?? 0) * 100;
    final cmd = [
      0xAA, 0x02,
      (peak ~/ 256), (peak % 256).toInt(),
      (flat ~/ 256), (flat % 256).toInt(),
      (valley ~/ 256), (valley % 256).toInt(),
      (service ~/ 256), (service % 256).toInt(),
      0xBB,
    ];
    await _sendCommand(cmd.map((e) => e.toInt()).toList());
    await Future.delayed(const Duration(milliseconds: 600));
    rateConfig.value = cfg;
    isSendingRate.value = false;
    return true;
  }

  // ─────────────────────────────────────────────────────────────
  //  设备状态 & 版本
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchStatus() async {
    await _sendCommand([0xAA, 0x03, 0x00, 0xBB]);
    await _mockFetchStatus();
  }

  Future<void> _mockFetchStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final random = Random();
    chargeState.value = '空闲';
    voltage.value = '${(215 + random.nextDouble() * 15).toStringAsFixed(1)} V';
    current.value = '${(random.nextDouble() * 5).toStringAsFixed(1)} A';
    power.value = '${(random.nextDouble() * 3.5).toStringAsFixed(2)} kW';
    temperature.value = '${30 + random.nextInt(20)} °C';
  }

  Future<void> fetchVersion() async {
    await _sendCommand([0xAA, 0x04, 0x00, 0xBB]);
    await Future.delayed(const Duration(milliseconds: 500));
    firmwareVersion.value = 'V1.2.5';
    hardwareVersion.value = 'V2.0';
    deviceModel.value = 'EV-CHARGER-7KW';
  }

  // ─────────────────────────────────────────────────────────────
  //  OTA 升级
  // ─────────────────────────────────────────────────────────────

  void setOtaFile(String path, String name) {
    otaFilePath.value = path;
    otaFileName.value = name;
    otaLog.clear();
    otaLog.add('[${_ts()}] 已选择: $name');
  }

  Future<void> startOta() async {
    if (otaFilePath.isEmpty) {
      Get.snackbar('请先选择升级包', '', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    otaState.value = OtaState.uploading;
    otaProgress.value = 0;
    otaLog.add('[${_ts()}] 开始传输升级包...');

    const totalChunks = 20;
    for (int i = 0; i < totalChunks; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      otaProgress.value = (i + 1) / totalChunks;
      otaLog.add('[${_ts()}] 发送分包 ${i + 1}/$totalChunks');
      await _sendCommand([0xAA, 0x05, i, ...List.filled(16, i), 0xBB]);
    }

    otaState.value = OtaState.verifying;
    otaLog.add('[${_ts()}] 传输完成，等待设备校验...');
    await Future.delayed(const Duration(seconds: 2));

    otaState.value = OtaState.success;
    otaProgress.value = 1.0;
    otaLog.add('[${_ts()}] ✅ OTA 升级成功！设备将自动重启。');
  }

  void resetOta() {
    otaState.value = OtaState.idle;
    otaProgress.value = 0;
    otaFilePath.value = '';
    otaFileName.value = '';
    otaLog.clear();
  }

  String _ts() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _scanSub?.cancel();
    _connStateSub?.cancel();
    _notifySub?.cancel();
    if (!isMock.value) {
      FlutterBluePlus.stopScan();
    }
    super.onClose();
  }
}
