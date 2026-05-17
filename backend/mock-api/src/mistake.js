const DEFAULT_CATEGORY = '未分类';

function seedMistakes() {
  return [
    {
      id: 'm001',
      question: 'for循环边界写错导致数组越界',
      wrongAnswer: 'i <= arr.length',
      correctAnswer: 'i < arr.length',
      reason: 'length 是元素个数，最后一个索引是 length-1',
      category: 'Java',
      tags: ['循环', '边界'],
      questionImagePath: '',
      wrongAnswerImagePath: '',
      correctAnswerImagePath: ''
    },
    {
      id: 'm002',
      question: '二分查找边界条件错误',
      wrongAnswer: 'while(l < r)',
      correctAnswer: 'while(l <= r)',
      reason: '漏掉最后一个候选值',
      category: '算法',
      tags: ['二分'],
      questionImagePath: '',
      wrongAnswerImagePath: '',
      correctAnswerImagePath: ''
    }
  ];
}

function asString(value, fallback = '') {
  if (value === undefined || value === null) return fallback;
  return String(value);
}

function normalizeMistake(input = {}, fallback = {}) {
  const merged = { ...fallback, ...input };
  const category = asString(merged.category, DEFAULT_CATEGORY).trim() || DEFAULT_CATEGORY;

  return {
    id: asString(merged.id || `m${Date.now()}`),
    question: asString(merged.question),
    wrongAnswer: asString(merged.wrongAnswer),
    correctAnswer: asString(merged.correctAnswer),
    reason: asString(merged.reason),
    category,
    tags: Array.isArray(merged.tags) ? merged.tags.map(String) : [],
    questionImagePath: asString(merged.questionImagePath),
    wrongAnswerImagePath: asString(merged.wrongAnswerImagePath),
    correctAnswerImagePath: asString(merged.correctAnswerImagePath)
  };
}

function matchesMistake(mistake, { keyword = '', category = '全部分类' } = {}) {
  const trimmedKeyword = keyword.trim().toLowerCase();
  const trimmedCategory = category.trim() || '全部分类';
  const okCategory = trimmedCategory === '全部分类' || mistake.category === trimmedCategory;
  const text = [
    mistake.question,
    mistake.wrongAnswer,
    mistake.correctAnswer,
    mistake.reason,
    mistake.category,
    ...(mistake.tags || [])
  ].join(' ').toLowerCase();
  const okKeyword = !trimmedKeyword || text.includes(trimmedKeyword);
  return okCategory && okKeyword;
}

function statsFor(mistakes) {
  const byCategory = {};
  for (const mistake of mistakes) {
    byCategory[mistake.category] = (byCategory[mistake.category] || 0) + 1;
  }
  return {
    total: mistakes.length,
    byCategory
  };
}

module.exports = {
  DEFAULT_CATEGORY,
  matchesMistake,
  normalizeMistake,
  seedMistakes,
  statsFor
};
