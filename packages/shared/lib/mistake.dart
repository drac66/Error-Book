class Mistake {
  final String id;
  final String question;
  final String wrongAnswer;
  final String correctAnswer;
  final String reason;
  final String category;
  final List<String> tags;
  final String questionImagePath;
  final String wrongAnswerImagePath;
  final String correctAnswerImagePath;

  const Mistake({
    required this.id,
    required this.question,
    required this.wrongAnswer,
    required this.correctAnswer,
    required this.reason,
    required this.category,
    this.tags = const [],
    this.questionImagePath = '',
    this.wrongAnswerImagePath = '',
    this.correctAnswerImagePath = '',
  });
}
