import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

/// BLE 示例日志条目
class BleLogEntry {
  final String time;
  final String message;
  final bool isSend; // true=发送, false=接收
  final List<int>? data;

  BleLogEntry({
    required this.time,
    required this.message,
    this.isSend = true,
    this.data,
  });
}

/// 蓝牙示例控制器
class BleDemoController extends GetxController {
  // ── 扫描 & 连接 ───────────────────────────────────────────────
  final isScanning = false.obs;
  final scanResults = <ScanResult>[].obs;
  final connectedDevice = Rxn<BluetoothDevice>();
  final connectionState = BluetoothConnectionState.disconnected.obs;
  final isConnecting = false.obs;

  /// 当前正在连接中的设备 remoteId
  final connectingDeviceId = Rxn<String>();

  /// 连接状态标记
  final isConnected = false.obs;

  // ── 发送数据日志 ───────────────────────────────────────────────
  final sendLogs = <BleLogEntry>[].obs;

  // ── 接收数据日志 ───────────────────────────────────────────────
  final receiveLogs = <BleLogEntry>[].obs;

  // ── 内部 ───────────────────────────────────────────────────────
  StreamSubscription? _scanSub;
  StreamSubscription? _connStateSub;
  StreamSubscription? _notifySub;

  /// 持有写入特征
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
      _addReceiveLog('设备已连接');
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
    _addReceiveLog('设备已断开');
  }

  // ─────────────────────────────────────────────────────────────
  //  服务发现 & 特征订阅
  // ─────────────────────────────────────────────────────────────

  /// 发现服务并订阅通知特征
  Future<void> _discoverServices(BluetoothDevice device) async {
    if (GetPlatform.isAndroid) {
      await device.requestMtu(512);
    }

    final services = await device.discoverServices();
    for (final service in services) {
      if (!service.uuid.toString().contains('1111')) continue;

      for (final char in service.characteristics) {
        if (char.uuid.toString().contains('2222')) {
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
    _addReceiveLog('收到通知: ${_formatHex(data)}', data: data);
  }

  // ─────────────────────────────────────────────────────────────
  //  发送数据
  // ─────────────────────────────────────────────────────────────

  Future<bool> _sendCommand(List<int> cmd) async {
    final char = _writeChar;
    if (char == null) {
      debugPrint('[BleDemo] _writeChar is null, device not connected');
      return false;
    }
    try {
      debugPrint("正在尝试写入特征值: ${_writeChar?.uuid.str}");
      debugPrint("待发送数据: $cmd");
      await char.write(cmd, withoutResponse: false);
      debugPrint(
          '[BleDemo] -> 发送 ${cmd.length} bytes: ${_formatHex(cmd)}');
      return true;
    } catch (e) {
      debugPrint('[BleDemo] _sendCommand error: $e');
      return false;
    }
  }

  /// 发送自定义数据
  Future<void> sendCustomData(List<int> data, String description) async {
    if (!isConnected.value) {
      Get.snackbar('未连接', '请先连接设备', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    _addSendLog(description, data: data);
    await _sendCommand(data);
  }

  // ─────────────────────────────────────────────────────────────
  //  日志辅助
  // ─────────────────────────────────────────────────────────────

  void _addSendLog(String message, {List<int>? data}) {
    final entry = BleLogEntry(
      time: _ts(),
      message: message,
      isSend: true,
      data: data,
    );
    sendLogs.insert(0, entry);
    // 限制日志数量
    if (sendLogs.length > 100) {
      sendLogs.removeLast();
    }
  }

  void _addReceiveLog(String message, {List<int>? data}) {
    final entry = BleLogEntry(
      time: _ts(),
      message: message,
      isSend: false,
      data: data,
    );
    receiveLogs.insert(0, entry);
    if (receiveLogs.length > 100) {
      receiveLogs.removeLast();
    }
  }

  void clearSendLogs() => sendLogs.clear();
  void clearReceiveLogs() => receiveLogs.clear();

  String _formatHex(List<int> data) {
    return data.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
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
