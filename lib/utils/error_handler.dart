import 'dart:developer' as developer;

class ErrorHandler {
  static void handleError(dynamic error, String context, {bool silent = true}) {
    // Log error silently to terminal without UI feedback
    developer.log('Error in $context: $error', name: 'ErrorHandler');
  }

  static bool isSupabaseRateLimit(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('ChannelRateLimitReached') ||
        errorString.contains('Too many channels');
  }

  static bool isTypeConversionError(dynamic error) {
    return error
        .toString()
        .contains('type \'int\' is not a subtype of type \'double\'');
  }
}
