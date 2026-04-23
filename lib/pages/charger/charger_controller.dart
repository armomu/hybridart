import 'dart:async';

import 'package:flutter/foundation.dart';
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
class ChargerController extends GetxController {
  // ── 扫描 & 连接 ───────────────────────────────────────────────
  final isScanning = false.obs;
  final scanResults = <ScanResult>[].obs;
  final connectedDevice = Rxn<BluetoothDevice>();
  final connectionState = BluetoothConnectionState.disconnected.obs;
  final isConnecting = false.obs;

  /// 当前正在连接中的设备 remoteId（用于列表中仅对该卡片显示 loading）
  final connectingDeviceId = Rxn<String>();

  /// 连接状态标记
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

  /// 持有写入特征，对端设备断开后置空
  BluetoothCharacteristic? _writeChar;

  // ─────────────────────────────────────────────────────────────
  //  扫描
  // ─────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    if (isScanning.value) return;
    scanResults.clear();
    isScanning.value = true;

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      Get.snackbar('蓝牙未开启', '请先开启手机蓝牙', snackPosition: SnackPosition.BOTTOM);
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
    await FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  // ─────────────────────────────────────────────────────────────
  //  连接 / 断开
  // ─────────────────────────────────────────────────────────────

  Future<void> connectDevice(BluetoothDevice device) async {
    if (isConnecting.value) return;
    isConnecting.value = true;
    connectingDeviceId.value = device.remoteId.str;
    stopScan();
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      connectedDevice.value = device;
      isConnected.value = true;

      _connStateSub?.cancel();
      _connStateSub = device.connectionState.listen((state) {
        connectionState.value = state;
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('设备已断开连接=============================');
          _onDisconnected();
        }
      });

      await _discoverServices(device);
      deviceStatus.value = '已连接';
    } catch (e) {
      Get.snackbar('连接失败', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isConnecting.value = false;
      connectingDeviceId.value = null;
    }
  }

  Future<void> disconnectDevice() async {
    await connectedDevice.value?.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    _writeChar = null;
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
  //  服务发现 & 特征订阅
  // ─────────────────────────────────────────────────────────────

  /// 发现服务并订阅通知特征
  /// TODO: 替换 UUID 为实际设备 UUID
  Future<void> _discoverServices(BluetoothDevice device) async {
    if (GetPlatform.isAndroid) {
      await device.requestMtu(512);
    }

    final services = await device.discoverServices();
    for (final service in services) {
      if (!service.uuid.toString().contains('1111')) continue;

      for (final char in service.characteristics) {
        if (char.uuid.toString().contains('2222')) {
          // 持有写入特征
          _writeChar = char;
          if (char.properties.notify || char.properties.indicate) {
            await char.setNotifyValue(true);
            _notifySub?.cancel();
            _notifySub = char.onValueReceived
                .listen((value) => _handleNotification(value));
          }
        }
      }
    }
  }

  /// 处理设备主动上报的通知数据
  void _handleNotification(List<int> data) {
    // TODO: 按实际协议解析 data
    debugPrint('=======================================================');
    debugPrint('Notification: $data');
  }

  // ─────────────────────────────────────────────────────────────
  //  发送命令
  // ─────────────────────────────────────────────────────────────

  Future<bool> _sendCommand(List<int> cmd) async {
    final char = _writeChar;
    if (char == null) {
      debugPrint(
          '[ChargerCtrl] _sendCommand: _writeChar is null, device not connected');
      return false;
    }
    try {
      debugPrint("正在尝试写入特征值: ${_writeChar?.uuid.str}");
      debugPrint("待发送数据: $cmd");
      await char.write(cmd, withoutResponse: false);
      debugPrint(
          '[ChargerCtrl] -> wrote ${cmd.length} bytes: ${cmd.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
      return true;
    } catch (e) {
      debugPrint('[ChargerCtrl] _sendCommand error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  充电记录
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchChargeRecords() async {
    isLoadingRecords.value = true;
    await _sendCommand([0xAA, 0x01, 0x00, 0xBB]);
    // TODO: 等待设备通过通知上报记录数据，此处暂无回调处理
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
      0xAA,
      0x02,
      (peak ~/ 256),
      (peak % 256).toInt(),
      (flat ~/ 256),
      (flat % 256).toInt(),
      (valley ~/ 256),
      (valley % 256).toInt(),
      (service ~/ 256),
      (service % 256).toInt(),
      0xBB,
    ];
    final ok = await _sendCommand(cmd.map((e) => e.toInt()).toList());
    if (ok) rateConfig.value = cfg;
    isSendingRate.value = false;
    return ok;
  }

  // ─────────────────────────────────────────────────────────────
  //  设备状态 & 版本
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchStatus() async {
    await _sendCommand([0xAA, 0x03, 0x00, 0xBB]);
    // TODO: 等待设备通知回调更新状态字段
  }

  Future<void> fetchVersion() async {
    await _sendCommand([0xAA, 0x04, 0x00, 0xBB]);
    // TODO: 等待设备通知回调更新版本字段
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
    // TODO: 通过通知回调接收校验结果，此处暂以超时模拟等待
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
    FlutterBluePlus.stopScan();
    super.onClose();
  }
}
