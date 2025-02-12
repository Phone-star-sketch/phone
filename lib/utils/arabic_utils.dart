String normalizeArabic(String input) {
  const arabicNormChar = {
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ة': 'ه',
    'ى': 'ي',
  };

  String normalized = input;
  arabicNormChar.forEach((key, value) {
    normalized = normalized.replaceAll(key, value);
  });

  return normalized.trim().toLowerCase();
}
