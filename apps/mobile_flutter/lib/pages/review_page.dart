import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/mistake.dart';
import '../models/notebook.dart';
import '../services/app_services.dart';
import 'notebook_review_detail_page.dart';
import 'review_checkin_page.dart';

class ReviewPage extends StatefulWidget {
  final AppServices services;
  final Future<void> Function() onChanged;
  final void Function(String notebookName, String mistakeTitle)?
      onStudyStateChanged;

  const ReviewPage({
    super.key,
    required this.services,
    required this.onChanged,
    this.onStudyStateChanged,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool loading = true;
  List<Notebook> notebooks = [];
  List<Mistake> allMistakes = [];
  String notebookKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
  }

  Future<void> _loadNotebooks() async {
    setState(() => loading = true);
    final nextNotebooks = await widget.services.notebooks.list();
    final nextMistakes = await widget.services.mistakes.list();
    if (!mounted) return;
    setState(() {
      notebooks = nextNotebooks;
      allMistakes = nextMistakes;
      loading = false;
    });
  }

  String _displayName(Notebook book) {
    return book.id == AppConfig.defaultNotebookId ? '全部错题' : book.name;
  }

  List<Notebook> get filteredNotebooks {
    final q = notebookKeyword.trim();
    if (q.isEmpty) return notebooks;

    return notebooks.where((book) {
      final aliases = <String>[
        _displayName(book),
        book.name,
        if (book.id == AppConfig.defaultNotebookId) '全部',
        if (book.id == AppConfig.defaultNotebookId) 'all',
        if (book.id == AppConfig.defaultNotebookId) '默认错题本',
      ];

      final bookMatched = aliases.any((text) => _fuzzyMatch(text, q));
      if (bookMatched) return true;

      final relatedMistakes = book.id == AppConfig.defaultNotebookId
          ? allMistakes
          : allMistakes.where((m) => m.notebookId == book.id);

      return relatedMistakes.any((m) {
        final haystacks = <String>[
          m.title,
          m.question,
          m.wrongAnswer,
          m.correctAnswer,
          m.reason,
          m.category,
          m.tags.join(' '),
        ];
        return haystacks.any((text) => _fuzzyMatch(text, q));
      });
    }).toList();
  }

  Future<void> _openNotebook(Notebook? notebook) async {
    final displayName = notebook == null ? '全部错题' : _displayName(notebook);
    widget.onStudyStateChanged?.call(displayName, '暂无');
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotebookReviewDetailPage(
          services: widget.services,
          notebook: notebook,
          onChanged: widget.onChanged,
          onStudyStateChanged: widget.onStudyStateChanged,
        ),
      ),
    );
    await _loadNotebooks();
    await widget.onChanged();
  }

  bool _fuzzyMatch(String text, String query) {
    final source = _normalize(text);
    final target = _normalize(query);
    if (target.isEmpty) return true;
    if (source.contains(target)) return true;

    final tokens =
        query.split(RegExp(r'[\s,，;；]+')).where((e) => e.trim().isNotEmpty).toList();
    if (tokens.length > 1) {
      return tokens.every((token) => _fuzzyMatch(text, token));
    }

    var idx = 0;
    for (final rune in source.runes) {
      if (idx < target.runes.length &&
          rune == target.runes.elementAt(idx)) {
        idx++;
      }
      if (idx == target.runes.length) return true;
    }
    return false;
  }

  String _normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF3),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFDCC9A2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '按错题本进入复习',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '支持跳跃式模糊搜索。既能搜错题本名，也能根据题干、答案、解析、标签把对应错题本筛出来。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6A7280),
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: '搜索错题本或题目关键词',
                  ),
                  onChanged: (v) => setState(() => notebookKeyword = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final checkin = await widget.services.mistakes
                  .reviewDashboardStats(notebookId: 'all');
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReviewCheckinPage(
                    streak: checkin.checkinStreak,
                    checkedInToday: checkin.checkedInToday,
                    todayReviewed: checkin.todayReviewed,
                    todayPlanned: checkin.todayPlanned,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.local_fire_department_outlined),
            label: const Text('学习打卡'),
          ),
          const SizedBox(height: 16),
          Text(
            '错题本',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          if (loading)
            const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredNotebooks.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF3),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFDCC9A2)),
              ),
              child: const Text('没有匹配的错题本'),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredNotebooks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (_, i) {
                final book = filteredNotebooks[i];
                final displayName = _displayName(book);
                return InkWell(
                  onTap: () => _openNotebook(book),
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
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE4D3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.menu_book_outlined,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '错题本',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF6A7280),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const Text(
                          '点击进入本册',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6A7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
