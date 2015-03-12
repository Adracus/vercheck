library cache;

import 'dart:io' show Platform;
import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'package:vercheck/vercheck.dart';
import 'package:redis_client/redis_client.dart';

Cache cache;

void initializeCache() {
  var redis = Platform.environment["REDIS_URL"];
  cache = null == redis ? new Cache() : new RedisCache(redis);
}

abstract class Cache {
  Future<Analysis> put(String identifier, Analysis value);
  
  Future<Analysis> get(String identifier);
  
  Future<bool> containsKey(identifier);
  
  factory Cache() => new MemoryCache();
  
  static String analysisToJson(Analysis analysis) {
    return JSON.encode(analysis.toJsonRepresentation());
  }
  
  static Analysis analysisFromJson(String json) {
    return new Analysis.fromJson(JSON.decode(json));
  }
}

class MemoryCache implements Cache {
  final Map<String, String> _cache = {};
  
  Future<Analysis> get(String identifier) {
    var json = _cache[identifier];
    if (null == json) return new Future.value();
    return new Future.value(Cache.analysisFromJson(json));
  }
  
  Future<Analysis> put(String identifier, Analysis value) {
    _cache[identifier] = Cache.analysisToJson(value);
    return new Future.value(value);
  }
  
  Future<bool> containsKey(identifier) {
    return new Future.value(_cache.containsKey(identifier));
  }
}

class RedisCache implements Cache {
  final String _connectionString;
  
  RedisCache(this._connectionString);
  
  Future<Analysis> get(String identifier) {
    return RedisClient.connect(_connectionString).then((client) {
      return client.get(identifier).then((json) {
        return Cache.analysisFromJson(json);
      });
    });
  }
  
  Future<bool> containsKey(String identifier) {
    return RedisClient.connect(_connectionString).then((client) {
      return client.exists(identifier);
    });
  }
  
  Future<Analysis> put(String identifier, Analysis value) {
    return RedisClient.connect(_connectionString).then((client) {
      return client.set(identifier, Cache.analysisToJson(value)).then((_) {
        return value;
      });
    });
  }
}