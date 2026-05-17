import 'package:error_book_mobile/models/app_stats.dart';
import 'package:error_book_mobile/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dashboard renders study overview and actions',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          stats: const AppStats(
            total: 3,
            reviewing: 2,
            mastered: 1,
            lastReviewedAt: null,
          ),
          recentMistakes: const [],
          onQuickAdd: () {},
          onStartReview: () {},
          currentNotebookName: '全部错题',
          currentMistakeTitle: '暂无',
          reviewStats: const ReviewDashboardStats(
            todayReviewed: 1,
            todayPlanned: 2,
            checkinStreak: 3,
            checkedInToday: false,
          ),
        ),
      ),
    );

    expect(find.text('今日学习仪表盘'), findsOneWidget);
    expect(find.text('开始复习'), findsOneWidget);
    expect(find.text('添加错题'), findsOneWidget);
    expect(find.text('今日已学'), findsOneWidget);
    expect(find.text('今日应学'), findsOneWidget);
  });
}
