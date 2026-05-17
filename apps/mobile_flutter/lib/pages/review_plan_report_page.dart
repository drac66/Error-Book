import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/app_stats.dart';
import '../models/notebook.dart';
import '../services/app_services.dart';
import 'review_checkin_page.dart';
import 'review_plan_session_page.dart';

class ReviewPlanReportPage extends StatefulWidget {
  final AppServices services;
  final Notebook? notebook;
  final Future<void> Function() onChanged;
  final void Function(String notebookName, String mistakeTitle)?
      onStudyStateChanged;

  const ReviewPlanReportPage({
    super.key,
    required this.services,
    required this.notebook,
    required this.onChanged,
    this.onStudyStateChanged,
  });

  @override
  State<ReviewPlanReportPage> createState() => _ReviewPlanReportPageState();
}

class _ReviewPlanReportPageState extends State<ReviewPlanReportPage> {
  bool loading = true;
  ReviewPlanReport report = const ReviewPlanReport(
    summary: ReviewDashboardStats.empty,
    overdueCount: 0,
    yesterdayUnmasteredCount: 0,
    hardMistakeCount: 0,
    coolingMistakeCount: 0,
    newMistakeCount: 0,
    totalPool: 0,
    bars: [],
  );

  String get notebookId {
    final id = widget.notebook?.id;
    if (id == null || id == AppConfig.defaultNotebookId) return 'all';
    return id;
  }
  String get notebookName =>
      (widget.notebook?.id == AppConfig.defaultNotebookId ||
              widget.notebook == null)
          ? '全部错题'
          : widget.notebook!.name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final next = await widget.services.mistakes.reviewPlanReport(
      notebookId: notebookId,
    );
    if (!mounted) return;
    setState(() {
      report = next;
      loading = false;
    });
  }

  Future<void> _startPlan() async {
    final remaining = await widget.services.mistakes.remainingPlannedReviewList(
      notebookId: notebookId,
    );
    if (!mounted) return;
    if (remaining.isEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewCheckinPage(
            streak: report.summary.checkinStreak,
            checkedInToday: report.summary.checkedInToday,
            todayReviewed: report.summary.todayReviewed,
            todayPlanned: report.summary.todayPlanned,
          ),
        ),
      );
      return;
    }
    widget.onStudyStateChanged?.call(notebookName, remaining.first.title);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewPlanSessionPage(
          services: widget.services,
          notebook: widget.notebook,
          notebookName: notebookName,
          onChanged: widget.onChanged,
          onStudyStateChanged: widget.onStudyStateChanged,
        ),
      ),
    );
    await widget.onChanged();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bars = report.bars;
    final maxBar = bars.fold<int>(1, (maxValue, item) {
      return item.value > maxValue ? item.value : maxValue;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('复习计划')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E3A5F), Color(0xFF325C8A)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notebookName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '今天的复习计划像一份学习报告：先看风险，再开始执行。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _TopMetric(
                              label: '已完成',
                              value: '${report.summary.todayReviewed}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TopMetric(
                              label: '总计划',
                              value: '${report.summary.todayPlanned}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TopMetric(
                              label: '连击',
                              value: '${report.summary.checkinStreak}天',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: '执行进度',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: report.summary.completionRate,
                          minHeight: 14,
                          backgroundColor: const Color(0xFFF3E8CF),
                          color: const Color(0xFFE76F51),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '今天已复习 ${report.summary.todayReviewed} / ${report.summary.todayPlanned} 题，剩余 ${report.summary.remaining} 题',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF5C6778),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: '计划分布',
                  child: SizedBox(
                    height: 210,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final bar in bars)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: _BarColumn(
                                label: bar.label,
                                value: bar.value,
                                maxValue: maxBar,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _InsightTile(
                      title: '昨日未掌握',
                      value: report.yesterdayUnmasteredCount,
                      note: '昨天复习后仍不稳，需要优先回访',
                    ),
                    _InsightTile(
                      title: '久未复习',
                      value: report.overdueCount,
                      note: '超过建议间隔，记忆有回落风险',
                    ),
                    _InsightTile(
                      title: '顽固错题',
                      value: report.hardMistakeCount,
                      note: '近期多次未掌握，建议重点拆解',
                    ),
                    _InsightTile(
                      title: '冷却中',
                      value: report.coolingMistakeCount,
                      note: '已连续掌握，暂时延后出现',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: '计划建议',
                  child: Text(
                    _adviceText(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                          color: const Color(0xFF45556C),
                        ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _startPlan,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    report.summary.remaining == 0 ? '查看打卡结果' : '开始今日计划',
                  ),
                ),
              ],
            ),
    );
  }

  String _adviceText() {
    if (report.summary.todayPlanned == 0) {
      return '今天没有需要处理的计划题目，可以去补录新错题，或者回顾已掌握内容。';
    }
    if (report.yesterdayUnmasteredCount > 0) {
      return '今天的重点应放在昨天仍未掌握的题目上，再处理久未复习和顽固错题。';
    }
    if (report.hardMistakeCount > 0) {
      return '当前计划里有一批顽固错题，建议边做边总结错因，避免只做机械重复。';
    }
    return '今天的计划整体比较健康，按顺序完成即可，系统会自动帮你延后稳定掌握的题目。';
  }
}

class _TopMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TopMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;

  const _BarColumn({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final heightFactor = maxValue == 0 ? 0.0 : value / maxValue;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor.clamp(0.08, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE76F51), Color(0xFFF2C46D)],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6A7280),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String title;
  final int value;
  final String note;

  const _InsightTile({
    required this.title,
    required this.value,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCC9A2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E3A5F),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6A7280),
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
