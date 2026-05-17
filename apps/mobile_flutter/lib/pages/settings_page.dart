import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_stats.dart';
import '../services/app_services.dart';

class SettingsPage extends StatefulWidget {
  final AppServices services;
  final AppStats stats;
  final Future<void> Function() onChanged;

  const SettingsPage({
    super.key,
    required this.services,
    required this.stats,
    required this.onChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool busy = false;

  Future<void> _resetSeed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重建示例数据'),
        content: const Text('当前本机错题会被清空，并恢复为内置示例数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重建'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => busy = true);
    await widget.services.migration.resetToSeed();
    await widget.onChanged();
    if (mounted) {
      setState(() => busy = false);
      _toast('示例数据已恢复');
    }
  }

  Future<void> _exportJson() async {
    setState(() => busy = true);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(
        dir.path,
        'error_book_export_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );
    await file.writeAsString(await widget.services.mistakes.exportJson());
    if (!mounted) return;
    setState(() => busy = false);
    _toast('已导出：${file.path}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '离线学习空间',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '当前数据和图片都保存在本机应用目录，适合独立使用和调试导出。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.analytics_outlined),
                  ),
                  title: const Text('数据统计'),
                  subtitle: Text(
                    '总错题 ${widget.stats.total} · 待复习 ${widget.stats.pending} · 已掌握 ${widget.stats.mastered}',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0ECFF).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.wifi_off_outlined),
                  ),
                  title: const Text('离线模式'),
                  subtitle: const Text('数据和图片保存在本机应用私有目录，不依赖后端服务'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  enabled: !busy,
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('导出本机调试 JSON'),
                  onTap: _exportJson,
                ),
                const Divider(height: 1),
                ListTile(
                  enabled: !busy,
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('重建示例数据'),
                  onTap: _resetSeed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0ECFF).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.info_outline),
              ),
              title: const Text('版本信息'),
              subtitle: const Text('学无止境 APK v1'),
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
