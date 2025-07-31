import 'dart:developer' as dev;

/// Простой централизованный логгер.
/// Использует dart:developer.log под капотом, чтобы избежать прямых print().
class Logger {
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log(message, level: 500, name: 'DEBUG', error: error, stackTrace: stackTrace);
  }

  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log(message, level: 800, name: 'INFO', error: error, stackTrace: stackTrace);
  }

  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log(message, level: 900, name: 'WARN', error: error, stackTrace: stackTrace);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log(message, level: 1000, name: 'ERROR', error: error, stackTrace: stackTrace);
  }
}
