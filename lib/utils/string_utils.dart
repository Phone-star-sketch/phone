import 'package:flutter/material.dart';
import 'package:relative_time/relative_time.dart';
import 'package:intl/intl.dart';

String removeSpecialArabicChars(String data) {
  final r = data
      .replaceAll("ـ", "")
      .replaceAll("أ", "ا")
      .replaceAll("إ", "ا")
      .replaceAll(RegExp(r"ي$"), "ى")
      .replaceAll("ي ", "ى");
  return r;
}

String relativeTimeFormatArabic(DateTime time) {
  return RelativeTime.locale(const Locale('ar')).format(time);
}

String fullExpressionArabicDate(DateTime time) {
  final relativeTime = relativeTimeFormatArabic(time);
  final date = DateFormat("yyyy/MM/dd").format(time);
  final t = DateFormat("hh:mm").format(time);

  return "${relativeTime} الموافق ${date} في تمام الساعة ${t}";
}
