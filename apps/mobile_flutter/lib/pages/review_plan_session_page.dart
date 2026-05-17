import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/app_stats.dart';
import '../models/mistake.dart';
import '../models/notebook.dart';
import '../services/app_services.dart';
import 'review_checkin_page.dart';

class ReviewPlanSessionPage extends StatefulWidget {
  final AppServices services;
  final Notebook? notebook;
  final String notebookName;
  final Future<void> Function() onChanged;
  final void Function(String notebookName, String mistakeTitle)?
      onStudyStateChanged;

  const ReviewPlanSessionPage({
    super.key,
    required this.services,
    required this.notebook,
    required this.notebookName,
    required this.onChanged,
    this.onStudyStateChanged,
  });

  @override
  State<ReviewPlanSessionPage> createState() => _ReviewPlanSessionPageState();
}

class _ReviewPlanSessionPageState extends State<ReviewPlanSessionPage> {
  bool loading = true;
  bool showAnswer = false;
  int index = 0;
  List<Mistake> plan = [];
  MistakeReviewMeta meta = MistakeReviewMeta.empty;
  ReviewDashboardStats summary = ReviewDashboardStats.empty;

  String get notebookId {
    final id = widget.notebook?.id;
    if (id == null || id == AppConfig.defaultNotebookId) return 'all';
    return id;
  }
  bool get completed => !loading && plan.isNotEmpty && index >= plan.length;
  Mistake get current => plan[index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final nextPlan = await widget.services.mistakes.remainingPlannedReviewList(
      notebookId: notebookId,
    );
    final nextSummary = await widget.services.mistakes.reviewDashboardStats(
      notebookId: notebookId,
    );
    if (!mounted) return;
    if (nextPlan.isEmpty) {
      setState(() {
        plan = [];
        summary = nextSummary;
        loading = false;
      });
      return;
    }

    final first = nextPlan.first;
    final firstMeta = await widget.services.mistakes.reviewMeta(first.id);
    if (!mounted) return;
    widget.onStudyStateChanged?.call(widget.notebookName, first.title);
    setState(() {
      plan = nextPlan;
      summary = nextSummary;
      meta = firstMeta;
      showAnswer = false;
      index = 0;
      loading = false;
    });
  }

  Future<void> _record(MasteryStatus status) async {
    final mistake = current;
    await widget.services.mistakes.recordReview(
      mistake.id,
      status,
      planNotebookId: notebookId,
    );
    await widget.onChanged();

    final nextIndex = index + 1;
    final nextSummary = await widget.services.mistakes.reviewDashboardStats(
      notebookId: notebookId,
    );
    if (!mounted) return;

    if (nextIndex >= plan.length) {
      setState(() {
        index = nextIndex;
        summary = nextSummary;
        showAnswer = false;
      });
      return;
    }

    final nextMistake = plan[nextIndex];
    final nextMeta = await widget.services.mistakes.reviewMeta(nextMistake.id);
    if (!mounted) return;
    widget.onStudyStateChanged?.call(widget.notebookName, nextMistake.title);
    setState(() {
      index = nextIndex;
      meta = nextMeta;
      summary = nextSummary;
      showAnswer = false;
    });
  }

  Future<void> _openCheckin() async {
    final latest = await widget.services.mistakes.reviewDashboardStats(
      notebookId: notebookId,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewCheckinPage(
          streak: latest.checkinStreak,
          checkedInToday: latest.checkedInToday,
          todayReviewed: latest.todayReviewed,
          todayPlanned: latest.todayPlanned,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (plan.isEmpty || completed) {
      return Scaffold(
        appBar: AppBar(title: const Text('今日计划')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBE4D3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        size: 42,
                        color: Color(0xFFE76F51),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '今日计划已完成',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.checkedInToday
                          ? '今天已经自动打卡，连续坚持 ${summary.checkinStreak} 天。'
                          : '计划题目已经清空，可以查看今天的打卡状态。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6A7280),
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _openCheckin,
                      icon: const Icon(Icons.local_fire_department_outlined),
                      label: const Text('查看打卡'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final progress = (index + 1) / plan.length;
    final m = current;
    return Scaffold(
      appBar: AppBar(title: Text('今日计划 · ${widget.notebookName}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第 ${index + 1} / ${plan.length} 题',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    color: const Color(0xFFF2C46D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '今天已完成 ${summary.todayReviewed} 题，剩余 ${math.max(0, plan.length - index - 1)} 题',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(text: '题干'),
                  Text(m.question.isEmpty ? '见题干图片' : m.question),
                  _image(m.questionImagePath),
                  const SizedBox(height: 14),
                  if (showAnswer) ...[
                    _SectionLabel(text: '正确答案'),
                    Text(m.correctAnswer.isEmpty ? '见答案图片' : m.correctAnswer),
                    _image(m.correctAnswerImagePath),
                    const SizedBox(height: 12),
                    _SectionLabel(text: '解析'),
                    Text(m.reason.isEmpty ? '未填写解析' : m.reason),
                  ] else
                    Container(
                      height: 110,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF4DF), Color(0xFFF8E3BF)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Text('先回忆，再看答案'),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCC9A2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加时间：${_fmt(m.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  '首次复习：${meta.firstReviewedAt == null ? '尚未开始' : _fmt(meta.firstReviewedAt!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  '当前状态：${m.masteryStatus.label} · 连续掌握 ${meta.consecutiveMastered} 次 · 已复习 ${meta.totalReviews} 次',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _image(String path) {
    if (path.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
