String normalizeArabicText(String text) {
  final diacritics = RegExp(r'[\u064B-\u0652]');
  final arabicLetters = {
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ى': 'ي',
    'ة': 'ه',
    'ؤ': 'و',
    'ئ': 'ي',
  };

  // Remove diacritics
  String normalized = text.replaceAll(diacritics, '');

  // Normalize different forms of the same letter
  arabicLetters.forEach((key, value) {
    normalized = normalized.replaceAll(key, value);
  });

  return normalized;
}
