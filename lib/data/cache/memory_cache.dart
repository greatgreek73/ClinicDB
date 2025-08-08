import 'dart:async';

/// A simple in-memory cache with TTL (Time To Live) support
class MemoryCache<K, V> {
  final Duration defaultTTL;
  final int maxSize;
  final Map<K, _CacheEntry<V>> _cache = {};
  Timer? _cleanupTimer;

  MemoryCache({
    this.defaultTTL = const Duration(minutes: 5),
    this.maxSize = 100,
  }) {
    // Schedule periodic cleanup of expired entries
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _removeExpiredEntries(),
    );
  }

  /// Get a value from the cache
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check if entry is expired
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    // Update access time for LRU
    entry.lastAccessed = DateTime.now();
    return entry.value;
  }

  /// Set a value in the cache with optional custom TTL
  void set(K key, V value, {Duration? ttl}) {
    // Enforce max size using LRU eviction
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      _evictLRU();
    }
    
    final expiry = DateTime.now().add(ttl ?? defaultTTL);
    _cache[key] = _CacheEntry(
      value: value,
      expiry: expiry,
      lastAccessed: DateTime.now(),
    );
  }

  /// Get a value from cache or compute it if not present
  Future<V> getOrCompute(K key, Future<V> Function() compute, {Duration? ttl}) async {
    final cached = get(key);
    if (cached != null) return cached;
    
    final value = await compute();
    set(key, value, ttl: ttl);
    return value;
  }

  /// Clear a specific key from cache
  void invalidate(K key) {
    _cache.remove(key);
  }

  /// Clear all entries from cache
  void clear() {
    _cache.clear();
  }

  /// Clear all entries matching a predicate
  void clearWhere(bool Function(K key) test) {
    _cache.removeWhere((key, _) => test(key));
  }

  /// Dispose of the cache and cleanup timer
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }

  void _removeExpiredEntries() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  void _evictLRU() {
    if (_cache.isEmpty) return;
    
    K? lruKey;
    DateTime? oldestAccess;
    
    for (final entry in _cache.entries) {
      if (oldestAccess == null || entry.value.lastAccessed.isBefore(oldestAccess)) {
        oldestAccess = entry.value.lastAccessed;
        lruKey = entry.key;
      }
    }
    
    if (lruKey != null) {
      _cache.remove(lruKey);
    }
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime expiry;
  DateTime lastAccessed;

  _CacheEntry({
    required this.value,
    required this.expiry,
    required this.lastAccessed,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}