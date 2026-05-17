import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_stats.dart';
import '../models/mistake.dart';
import '../services/app_services.dart';

class MistakeReviewPage extends StatefulWidget {
  final AppServices services;
  final Mistake mistake;
  final Future<void> Function() onChanged;
  final String planNotebookId;

  const MistakeReviewPage({
    super.key,
    required this.services,
    required this.mistake,
    required this.onChanged,
    this.planNotebookId = 'all',
  });

  @override
  State<MistakeReviewPage> createState() => _MistakeReviewPageState();
}

class _MistakeReviewPageState extends State<MistakeReviewPage> {
  bool showAnswer = false;
  bool loadingMeta = true;
  MistakeReviewMeta meta = MistakeReviewMeta.empty;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final next = await widget.services.mistakes.reviewMeta(widget.mistake.id);
    if (!mounted) return;
    setState(() {
      meta = next;
      loadingMeta = false;
    });
  }

  Future<void> _record(MasteryStatus status) async {
    await widget.services.mistakes.recordReview(
      widget.mistake.id,
      status,
      planNotebookId: widget.planNotebookId,
    );
    await widget.onChanged();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final m = widget.mistake;
    return Scaffold(
      appBar: AppBar(title: const Text('错题复习')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            '先回忆答案，再翻卡',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('题干'),
                  Text(m.question.isEmpty ? '见题干图片' : m.question),
                  _image(m.questionImagePath),
                  const SizedBox(height: 12),
                  if (showAnswer) ...[
                    _label('正确答案'),
                    Text(m.correctAnswer.isEmpty ? '见答案图片' : m.correctAnswer),
                    _image(m.correctAnswerImagePath),
                    const SizedBox(height: 10),
                    _label('解析'),
                    Text(m.reason.isEmpty ? '未填写解析' : m.reason),
                  ] else
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF4DF), Color(0xFFF8E3BF)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text('答案已隐藏'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!showAnswer)
            FilledButton.icon(
              onPressed: () => setState(() => showAnswer = true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('显示答案'),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _record(MasteryStatus.fresh),
                        child: const Text('还不会'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _record(MasteryStatus.reviewing),
                        child: const Text('继续复习'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => _record(MasteryStatus.mastered),
                  child: const Text('已掌握'),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFDCC9A2).withValues(alpha: 0.85),
              ),
            ),
            child: loadingMeta
                ? const LinearProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '添加时间：${_fmt(m.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '首次复习：${meta.firstReviewedAt == null ? '尚未开始' : _fmt(meta.firstReviewedAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '掌握状态：${m.masteryStatus.label} · 已复习 ${meta.totalReviews} 次 · 连续掌握 ${meta.consecutiveMastered} 次',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );

  Widget _image(String path) {
    if (path.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          height: 180,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox(
            height: 80,
            child: Center(child: Text('图片不可用')),
          ),
        ),
      ),
    );
  }
}
