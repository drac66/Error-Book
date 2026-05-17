import 'package:flutter/material.dart';

class ReviewCheckinPage extends StatelessWidget {
  final int streak;
  final bool checkedInToday;
  final int todayReviewed;
  final int todayPlanned;

  const ReviewCheckinPage({
    super.key,
    required this.streak,
    required this.checkedInToday,
    this.todayReviewed = 0,
    this.todayPlanned = 0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = todayPlanned == 0 ? 1.0 : todayReviewed / todayPlanned;

    return Scaffold(
      appBar: AppBar(title: const Text('学习打卡')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8E3BF), Color(0xFFF7F1E3)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      checkedInToday ? '今日已自动打卡' : '今日尚未完成打卡',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE76F51), Color(0xFFF2C46D)],
                        ),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        size: 58,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '连续打卡 $streak 天',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      checkedInToday
                          ? '今天的学习任务已经完成，节奏保持得很好。'
                          : '继续完成今日计划，系统会自动为你打卡。',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54, height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFF3E8CF),
                        color: const Color(0xFFE76F51),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '今日进度 $todayReviewed / $todayPlanned',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
