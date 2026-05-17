class AppStats {
  final int total;
  final int reviewing;
  final int mastered;
  final DateTime? lastReviewedAt;

  const AppStats({
    required this.total,
    required this.reviewing,
    required this.mastered,
    required this.lastReviewedAt,
  });

  int get pending => total - mastered;

  static const empty = AppStats(
    total: 0,
    reviewing: 0,
    mastered: 0,
    lastReviewedAt: null,
  );
}

class ReviewDashboardStats {
  final int todayReviewed;
  final int todayPlanned;
  final int checkinStreak;
  final bool checkedInToday;

  const ReviewDashboardStats({
    required this.todayReviewed,
    required this.todayPlanned,
    required this.checkinStreak,
    required this.checkedInToday,
  });

  int get remaining => (todayPlanned - todayReviewed).clamp(0, todayPlanned);
  double get completionRate =>
      todayPlanned == 0 ? 1 : todayReviewed / todayPlanned;

  static const empty = ReviewDashboardStats(
    todayReviewed: 0,
    todayPlanned: 0,
    checkinStreak: 0,
    checkedInToday: false,
  );
}

class ReviewPlanBarDatum {
  final String label;
  final int value;

  const ReviewPlanBarDatum({
    required this.label,
    required this.value,
  });
}

class ReviewPlanReport {
  final ReviewDashboardStats summary;
  final int overdueCount;
  final int yesterdayUnmasteredCount;
  final int hardMistakeCount;
  final int coolingMistakeCount;
  final int newMistakeCount;
  final int totalPool;
  final List<ReviewPlanBarDatum> bars;

  const ReviewPlanReport({
    required this.summary,
    required this.overdueCount,
    required this.yesterdayUnmasteredCount,
    required this.hardMistakeCount,
    required this.coolingMistakeCount,
    required this.newMistakeCount,
    required this.totalPool,
    required this.bars,
  });
}

class MistakeReviewMeta {
  final DateTime? firstReviewedAt;
  final int totalReviews;
  final int totalWrongReviews;
  final int totalMasteredReviews;
  final int consecutiveMastered;

  const MistakeReviewMeta({
    required this.firstReviewedAt,
    required this.totalReviews,
    required this.totalWrongReviews,
    required this.totalMasteredReviews,
    required this.consecutiveMastered,
  });

  bool get hasReviewed => totalReviews > 0;

  static const empty = MistakeReviewMeta(
    firstReviewedAt: null,
    totalReviews: 0,
    totalWrongReviews: 0,
    totalMasteredReviews: 0,
    consecutiveMastered: 0,
  );
}
