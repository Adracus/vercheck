library cache;

import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'package:vercheck/vercheck.dart';
import 'package:crypto/crypto.dart';
import 'package:redis_client/redis_client.dart';

abstract class Cache {
  Future<Analysis> put(identifier, Analysis value);
  
  Future<Analysis> get(identifier);
  
  Future<bool> containsKey(identifier);
  
  factory Cache() => new MemoryCache();
  
  static String hashIdentifier(identifier) {
    if (identifier is! String && identifier is! RepoSlug)
      throw new ArgumentError.value(identifier);
    
    var str = identifier is String ? "pub/packages/$identifier" :
      "github/${identifier.owner}/${identifier.repo}";
      
    var shasum = (new SHA256()
      ..add(str.codeUnits))
      .close();
    
    return CryptoUtils.bytesToHex(shasum);
  }
  
  static String analysisToJson(Analysis analysis) {
    return JSON.encode(analysis.toJsonRepresentation());
  }
  
  static Analysis analysisFromJson(String json) {
    return new Analysis.fromJson(JSON.decode(json));
  }
}

class MemoryCache implements Cache {
  final Map<String, String> _cache = {};
  
  Future<Analysis> get(identifier) {
    var hash = Cache.hashIdentifier(identifier);
    var json = _cache[hash];
    if (null == json) return new Future.value();
    return new Future.value(Cache.analysisFromJson(json));
  }
  
  Future<Analysis> put(identifier, Analysis value) {
    var hash = Cache.hashIdentifier(identifier);
    _cache[hash] = Cache.analysisToJson(value);
    return new Future.value(value);
  }
  
  Future<bool> containsKey(identifier) {
    var hash = Cache.hashIdentifier(identifier);
    return new Future.value(_cache.containsKey(identifier));
  }
}

class RedisCache implements Cache {
  final String _connectionString;
  
  RedisCache(this._connectionString);
  
  Future<Analysis> get(identifier) {
    var hash = Cache.hashIdentifier(identifier);
    return RedisClient.connect(_connectionString).then((client) {
      return client.get(hash).then((json) {
        if (null == json) return null;
        return Cache.analysisFromJson(json);
      });
    });
  }
  
  Future<bool> containsKey(identifier) {
    return get(identifier).then((analysis) {
      return null != analysis;
    });
  }
  
  Future<Analysis> put(identifier, Analysis value) {
    var hash = Cache.hashIdentifier(identifier);
    return RedisClient.connect(_connectionString).then((client) {
      return client.set(hash, Cache.analysisToJson(value)).then((_) {
        return value;
      });
    });
  }
}