import 'package:error_book_mobile/models/mistake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mistake JSON fills defaults and preserves optional fields', () {
    final mistake = Mistake.fromJson({
      'id': 'm1',
      'question': '题干',
      'category': '',
      'tags': ['数学'],
      'questionImagePath': '/tmp/q.png',
    });

    expect(mistake.category, '未分类');
    expect(mistake.tags, ['数学']);
    expect(mistake.questionImagePath, '/tmp/q.png');
    expect(mistake.difficultyLevel, 3);
    expect(mistake.importanceLevel, 3);
    expect(mistake.toJson()['wrongAnswerImagePath'], '');
  });
}
