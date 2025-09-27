import 'dart:async';
import 'dart:developer' as developer;

class DatabaseConnectionManager {
  static final DatabaseConnectionManager _instance =
      DatabaseConnectionManager._internal();
  factory DatabaseConnectionManager() => _instance;
  DatabaseConnectionManager._internal();

  static const int MAX_CONCURRENT_CONNECTIONS = 5;
  static const Duration CONNECTION_TIMEOUT = Duration(seconds: 30);

  int _activeConnections = 0;
  final List<Completer<void>> _waitingQueue = [];

  /// Get a connection slot (wait if max connections reached)
  Future<void> acquireConnection() async {
    if (_activeConnections < MAX_CONCURRENT_CONNECTIONS) {
      _activeConnections++;
      developer.log('Connection acquired. Active: $_activeConnections',
          name: 'DatabaseConnectionManager');
      return;
    }

    // Wait in queue
    final completer = Completer<void>();
    _waitingQueue.add(completer);

    developer.log('Connection queued. Queue length: ${_waitingQueue.length}',
        name: 'DatabaseConnectionManager');

    await completer.future.timeout(
      CONNECTION_TIMEOUT,
      onTimeout: () {
        _waitingQueue.remove(completer);
        throw TimeoutException('Connection timeout', CONNECTION_TIMEOUT);
      },
    );
  }

  /// Release a connection slot
  void releaseConnection() {
    if (_activeConnections > 0) {
      _activeConnections--;

      developer.log('Connection released. Active: $_activeConnections',
          name: 'DatabaseConnectionManager');

      // Process next in queue
      if (_waitingQueue.isNotEmpty) {
        final nextCompleter = _waitingQueue.removeAt(0);
        _activeConnections++;
        nextCompleter.complete();
      }
    }
  }

  /// Execute a database operation with connection management
  Future<T> executeWithConnection<T>(Future<T> Function() operation) async {
    await acquireConnection();
    try {
      return await operation();
    } finally {
      releaseConnection();
    }
  }

  /// Get current connection stats
  Map<String, int> getStats() {
    return {
      'active': _activeConnections,
      'queued': _waitingQueue.length,
    };
  }

  /// Reset connection manager (useful for testing)
  void reset() {
    _activeConnections = 0;
    for (final completer in _waitingQueue) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Connection manager reset'));
      }
    }
    _waitingQueue.clear();
  }
}
