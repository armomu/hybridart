import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter生命周期测试',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LifecycleTestHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LifecycleTestHome extends StatefulWidget {
  const LifecycleTestHome({super.key});

  @override
  State<LifecycleTestHome> createState() => _LifecycleTestHomeState();
}

class _LifecycleTestHomeState extends State<LifecycleTestHome> {
  bool _showChildWidget = true;
  String _parentTitle = '父组件标题';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生命周期测试中心'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 控制面板
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                const Text(
                  '父组件控制面板',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showChildWidget = !_showChildWidget;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_showChildWidget ? '销毁子组件' : '创建子组件'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _parentTitle =
                              _parentTitle == '父组件标题' ? '更新后的标题' : '父组件标题';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('更新父组件参数'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('当前父组件标题: $_parentTitle'),
              ],
            ),
          ),

          // 生命周期日志显示区域
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black87,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.black54,
                    child: const Row(
                      children: [
                        Icon(Icons.terminal, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '生命周期日志输出',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: LifecycleLogger(),
                  ),
                ],
              ),
            ),
          ),

          // 子组件显示区域
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: _showChildWidget
                  ? LifecycleTestWidget(
                      key: ValueKey('test_$_showChildWidget'),
                      title: _parentTitle,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '子组件已销毁',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// 修改点：使用 ValueNotifier 简单管理日志状态，避免复杂的静态 State 引用
final ValueNotifier<List<String>> logNotifier = ValueNotifier<List<String>>([]);

class LifecycleLogger extends StatelessWidget {
  const LifecycleLogger({super.key});

  static void addLog(String message) {
    final String timeLog =
        '${DateTime.now().toString().substring(11, 19)} - $message';
    // 异步执行，确保不在 build 过程中触发更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLogs = List<String>.from(logNotifier.value);
      currentLogs.insert(0, timeLog);
      if (currentLogs.length > 50) currentLogs.removeLast();
      logNotifier.value = currentLogs;
    });
    debugPrint('🔵 [生命周期] $message');
  }

  static void clearLogs() {
    logNotifier.value = [];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: logNotifier,
      builder: (context, logs, _) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getLogColor(logs[index]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      logs[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: clearLogs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('清空日志'),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('initState')) return Colors.green[700]!;
    if (log.contains('dispose')) return Colors.red[700]!;
    if (log.contains('setState')) return Colors.orange[700]!;
    if (log.contains('didUpdateWidget')) return Colors.purple[700]!;
    if (log.contains('didChangeDependencies')) return Colors.cyan[700]!;
    if (log.contains('deactivate')) return Colors.yellow[800]!;
    if (log.contains('build')) return Colors.blue[700]!;
    return Colors.grey[800]!;
  }
}

class LifecycleTestWidget extends StatefulWidget {
  final String title;

  const LifecycleTestWidget({
    super.key,
    required this.title,
  });

  @override
  State<LifecycleTestWidget> createState() {
    LifecycleLogger.addLog('⚡ createState - 创建 State 对象');
    return _LifecycleTestWidgetState();
  }
}

class _LifecycleTestWidgetState extends State<LifecycleTestWidget> {
  int _counter = 0;
  late String _localData;

  _LifecycleTestWidgetState() {
    LifecycleLogger.addLog('🏗️ 构造函数执行');
  }

  @override
  void initState() {
    super.initState();
    _LifecycleTestWidgetState.addLog('🌱 initState - 初始化开始');
    _localData = '初始时间: ${DateTime.now().toString().substring(11, 19)}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _LifecycleTestWidgetState.addLog('🔄 didChangeDependencies');
  }

  @override
  Widget build(BuildContext context) {
    _LifecycleTestWidgetState.addLog('🎨 build - 构建UI (计数器: $_counter)');
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.code, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text('📝 传入: ${widget.title}'),
            Text('🔢 计数: $_counter'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _LifecycleTestWidgetState.addLog('🔘 点击增加计数');
                    setState(() {
                      _counter++;
                    });
                  },
                  child: const Text('增加'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _LifecycleTestWidgetState.addLog('🔄 点击强制重建');
                    setState(() {});
                  },
                  child: const Text('刷新'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant LifecycleTestWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _LifecycleTestWidgetState.addLog('🔄 didUpdateWidget');
    if (oldWidget.title != widget.title) {
      _LifecycleTestWidgetState.addLog('   ⚠️ 标题已变: ${widget.title}');
    }
  }

  @override
  void deactivate() {
    _LifecycleTestWidgetState.addLog('⚠️ deactivate - 即将移除');
    super.deactivate();
  }

  @override
  void dispose() {
    LifecycleLogger.addLog('🗑️ dispose - 永久销毁');
    super.dispose();
  }

  static void addLog(String message) {
    LifecycleLogger.addLog(message);
  }
}
