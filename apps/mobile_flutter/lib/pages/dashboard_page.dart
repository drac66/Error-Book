import 'package:flutter/material.dart';

import '../models/app_stats.dart';
import '../models/mistake.dart';

class DashboardPage extends StatelessWidget {
  final AppStats stats;
  final List<Mistake> recentMistakes;
  final VoidCallback onQuickAdd;
  final VoidCallback onStartReview;
  final ValueChanged<Mistake>? onOpenMistake;
  final ValueChanged<String>? onOpenMetric;
  final String currentNotebookName;
  final String currentMistakeTitle;
  final ReviewDashboardStats reviewStats;

  const DashboardPage({
    super.key,
    required this.stats,
    required this.recentMistakes,
    required this.onQuickAdd,
    required this.onStartReview,
    this.onOpenMistake,
    this.onOpenMetric,
    required this.currentNotebookName,
    required this.currentMistakeTitle,
    required this.reviewStats,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('学习总览')),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _HeroGlowCard(
              title: '今日学习仪表盘',
              subtitle: _lastReviewText(),
              todayNeedReview: reviewStats.todayPlanned,
              todayReviewed: reviewStats.todayReviewed,
              streak: reviewStats.checkinStreak,
              onQuickAdd: onQuickAdd,
              onStartReview: onStartReview,
            ),
            const SizedBox(height: 18),
            Text(
              '当前进度',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF243447),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: '正在学习',
                    value: currentNotebookName,
                    icon: Icons.menu_book_outlined,
                    onTap: onOpenMetric == null ? null : () => onOpenMetric!('current'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: '已掌握',
                    value: stats.mastered.toString(),
                    icon: Icons.task_alt_outlined,
                    onTap: onOpenMetric == null ? null : () => onOpenMetric!('mastered'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: '待巩固',
                    value: stats.pending.toString(),
                    icon: Icons.pending_actions_outlined,
                    onTap: onOpenMetric == null ? null : () => onOpenMetric!('pending'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
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
                    '学习提示',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reviewStats.todayPlanned == 0
                        ? '今天没有待复习题目，可以去整理新错题或回顾已掌握内容。'
                        : '今日计划会优先覆盖高重要、高难度、久未复习和近期连续出错的题目。',
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: const Color(0xFF5C6778),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: (onOpenMistake != null && recentMistakes.isNotEmpty)
                  ? () => onOpenMistake!(recentMistakes.first)
                  : null,
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF7EC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDCC9A2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE4D3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.play_circle_outline),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recentMistakes.isEmpty
                            ? '当前没有正在学习的题目'
                            : '继续学习：$currentMistakeTitle',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (recentMistakes.isNotEmpty) const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '最近更新',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (recentMistakes.isEmpty)
              const _EmptyBlock(message: '还没有错题记录，先添加一道题开始整理。')
            else
              ...recentMistakes.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentCard(
                    mistake: m,
                    onTap: onOpenMistake == null ? null : () => onOpenMistake!(m),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _lastReviewText() {
    final last = stats.lastReviewedAt;
    if (last == null) return '还没有复习记录';
    return '最近复习：${last.year}-${_two(last.month)}-${_two(last.day)} ${_two(last.hour)}:${_two(last.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFCF6), Color(0xFFF8EDD6)],
          ),
          border: Border.all(color: const Color(0xFFDCC9A2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB89C7A).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE4D3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 18),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6A7280),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroGlowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int todayNeedReview;
  final int todayReviewed;
  final int streak;
  final VoidCallback onQuickAdd;
  final VoidCallback onStartReview;

  const _HeroGlowCard({
    required this.title,
    required this.subtitle,
    required this.todayNeedReview,
    required this.todayReviewed,
    required this.streak,
    required this.onQuickAdd,
    required this.onStartReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF325C8A)],
        ),
        border: Border.all(color: const Color(0xFF355A83)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2C46D).withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: '今日已学',
                        value: '$todayReviewed',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStat(
                        label: '今日应学',
                        value: '$todayNeedReview',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStat(
                        label: '连续打卡',
                        value: '$streak 天',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onStartReview,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('开始复习'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onQuickAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('添加错题'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final Mistake mistake;
  final VoidCallback? onTap;

  const _RecentCard({required this.mistake, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          mistake.hasImage ? Icons.image_outlined : Icons.notes_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          mistake.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${mistake.category} · ${mistake.masteryStatus.label} · 更新 ${_fmt(mistake.updatedAt)}',
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _EmptyBlock extends StatelessWidget {
  final String message;

  const _EmptyBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCC9A2)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6A7280),
            ),
      ),
    );
  }
}
