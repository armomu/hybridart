import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

  factory ChargeRecord.fromMock(int index) {
    return ChargeRecord(
      id: 'REC${1000 + index}',
      startTime: '2026-04-${(index + 1).toString().padLeft(2, '0')} 08:${(index * 7 % 60).toString().padLeft(2, '0')}',
      endTime: '2026-04-${(index + 1).toString().padLeft(2, '0')} 10:${(index * 7 % 60).toString().padLeft(2, '0')}',
      energy: 15.0 + index * 2.3,
      fee: (15.0 + index * 2.3) * 0.85,
      status: index % 3 == 0 ? '异常中断' : '正常完成',
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
class ChargerController extends GetxController {
  // ── 扫描 & 连接 ──────────────────────────────────────────────
  final isScanning = false.obs;
  final scanResults = <ScanResult>[].obs;
  final connectedDevice = Rxn<BluetoothDevice>();
  final connectionState = BluetoothConnectionState.disconnected.obs;
  final isConnecting = false.obs;

  // ── 设备信息 ──────────────────────────────────────────────────
  final deviceStatus = '未连接'.obs;
  final firmwareVersion = '—'.obs;
  final hardwareVersion = '—'.obs;
  final deviceModel = '—'.obs;
  final chargeState = '—'.obs; // 充电状态
  final voltage = '—'.obs;
  final current = '—'.obs;
  final power = '—'.obs;
  final temperature = '—'.obs;

  // ── 充电记录 ──────────────────────────────────────────────────
  final chargeRecords = <ChargeRecord>[].obs;
  final isLoadingRecords = false.obs;

  // ── 费率配置 ──────────────────────────────────────────────────
  final rateConfig = RateConfig().obs;
  final isSendingRate = false.obs;

  // ── OTA ──────────────────────────────────────────────────────
  final otaState = OtaState.idle.obs;
  final otaProgress = 0.0.obs;
  final otaFilePath = ''.obs;
  final otaFileName = ''.obs;
  final otaLog = <String>[].obs;

  // ── 内部 ──────────────────────────────────────────────────────
  StreamSubscription? _scanSub;
  StreamSubscription? _connStateSub;
  StreamSubscription? _notifySub;

  // 模拟用 Service/Characteristic UUID（实际根据设备协议填写）
  static const String _serviceUUID = '0000fff0-0000-1000-8000-00805f9b34fb';
  static const String _writeCharUUID = '0000fff1-0000-1000-8000-00805f9b34fb';
  static const String _notifyCharUUID = '0000fff2-0000-1000-8000-00805f9b34fb';

  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  // ─────────────────────────────────────────────────────────────
  //  扫描
  // ─────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    if (isScanning.value) return;
    scanResults.clear();

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      Get.snackbar('蓝牙未开启', '请先开启手机蓝牙',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isScanning.value = true;
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
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      connectedDevice.value = device;

      _connStateSub?.cancel();
      _connStateSub = device.connectionState.listen((state) {
        connectionState.value = state;
        if (state == BluetoothConnectionState.disconnected) {
          _onDisconnected();
        }
      });

      await _discoverServices(device);
      deviceStatus.value = '已连接';

      // 连接成功后模拟获取初始数据
      await _mockFetchStatus();
    } catch (e) {
      Get.snackbar('连接失败', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> disconnectDevice() async {
    await connectedDevice.value?.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    connectedDevice.value = null;
    deviceStatus.value = '已断开';
    chargeState.value = '—';
    voltage.value = '—';
    current.value = '—';
    power.value = '—';
    temperature.value = '—';
    firmwareVersion.value = '—';
    _writeChar = null;
    _notifyChar = null;
  }

  // ─────────────────────────────────────────────────────────────
  //  发现服务 & 特征
  // ─────────────────────────────────────────────────────────────

  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final service in services) {
      if (service.serviceUuid.toString().toLowerCase() ==
          _serviceUUID.toLowerCase()) {
        for (final char in service.characteristics) {
          final uuid = char.characteristicUuid.toString().toLowerCase();
          if (uuid == _writeCharUUID.toLowerCase()) {
            _writeChar = char;
          } else if (uuid == _notifyCharUUID.toLowerCase()) {
            _notifyChar = char;
            await char.setNotifyValue(true);
            _notifySub?.cancel();
            _notifySub = char.onValueReceived.listen(_handleNotification);
          }
        }
      }
    }
  }

  void _handleNotification(List<int> data) {
    // 解析设备上报数据（根据实际协议解包）
    if (kDebugMode) {
      debugPrint('BLE notify: ${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  发送命令（真实场景按协议封包，此处做模拟）
  // ─────────────────────────────────────────────────────────────

  Future<bool> _sendCommand(List<int> cmd) async {
    if (_writeChar == null) {
      // 设备未连接时走模拟分支
      return true;
    }
    try {
      await _writeChar!.write(Uint8List.fromList(cmd), withoutResponse: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  充电记录
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchChargeRecords() async {
    isLoadingRecords.value = true;
    // 发送"查询记录"指令 0x01
    await _sendCommand([0xAA, 0x01, 0x00, 0xBB]);
    // 模拟延迟 + 返回假数据
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
    // 模拟协议封包: 0xAA 0x02 [4个费率各2字节] 0xBB
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
    chargeState.value = '空闲';
    voltage.value = '220.3 V';
    current.value = '0.0 A';
    power.value = '0.0 kW';
    temperature.value = '32 °C';
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
    otaLog.add('[${_ts()}] 已选择文件: $name');
  }

  Future<void> startOta() async {
    if (otaFilePath.isEmpty) {
      Get.snackbar('请先选择升级包', '', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    otaState.value = OtaState.uploading;
    otaProgress.value = 0;
    otaLog.add('[${_ts()}] 开始传输升级包...');

    // 模拟分包传输
    const totalChunks = 20;
    for (int i = 0; i < totalChunks; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      otaProgress.value = (i + 1) / totalChunks;
      otaLog.add('[${_ts()}] 发送分包 ${i + 1}/$totalChunks');

      // 模拟发送命令 0xAA 0x05 [chunk_index] [data...] 0xBB
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
    FlutterBluePlus.stopScan();
    super.onClose();
  }
}
