library vercheck.dependency;

import 'package:quiver/core.dart';
import 'package:pub_semver/pub_semver.dart' show VersionConstraint;

import 'vercheck_http.dart';

class Dependency {
  final String name;
  final VersionConstraint version;
  final DependencySource source;
  
  Dependency(this.name, this.source, this.version);
  
  static Set<Dependency> dependenciesFromJson(Map<String, dynamic> dependencies) {
    var result = new Set();
    dependencies.forEach((name, json) {
      var version = versionFromJson(json);
      var source = new DependencySource.fromJson(name, json);
      result.add(new Dependency(name, source, version));
    });
    return result;
  }
  
  static VersionConstraint versionFromJson(json) {
    if (json is String) {
      return new VersionConstraint.parse(json);
    }
    if (json is Map<String, dynamic>) {
      if (json.containsKey("version"))
        return new VersionConstraint.parse(json["version"]);
    }
    return null;
  }
  
  operator==(other) {
    if (other is! Dependency) return false;
    return this.name == other.name &&
           this.version == other.version &&
           this.source == other.source;
  }
  
  int get hashCode => hash3(name, version, source);
}

abstract class DependencySource {
  factory DependencySource.fromJson(String name, dynamic json) {
    if (json is String)
      return new HostedSource(name);
    if (json is! Map<String, dynamic>)
      throw new ArgumentError.value(json);
    
    if (json.containsKey("git"))
      return new GitSource.fromJson(json["git"]);
    
    if (json.containsKey("path"))
      return new PathSource(json["path"]);
    
    throw new DependencySourceParseException(json);
  }
}

class DependencySourceParseException implements Exception {
  final Map<String, dynamic> json;
  
  DependencySourceParseException(this.json);
  
  toString() => "Could not parse json: \n$json";
}

class GitSource implements DependencySource {
  final String ref;
  final Uri url;
  
  GitSource(this.url, [this.ref]);
  
  factory GitSource.fromJson(dynamic json) {
    if (json is String) return new GitSource(Uri.parse(json));
    if (json is Map<String, String>) {
      var url = Uri.parse(json["url"]);
      var ref = json["ref"];
      return new GitSource(url, ref);
    }
    throw new ArgumentError.value(json);
  }
  
  operator==(other) {
    if (other is! GitSource) return false;
    return this.ref == other.ref && this.url == other.url;
  }
  
  int get hashCode => hash2(ref, url);
}

class PathSource implements DependencySource {
  final String path;
  
  PathSource(this.path);
  
  operator==(other) {
    if (other is! PathSource) return false;
    return this.path == other.path;
  }
  
  int get hashCode => path.hashCode;
}

class HostedSource implements DependencySource {
  final Uri url;
  final String name;
  
  HostedSource(this.name, [Uri url])
      : url = null == url ? defaultPubUrl : url;
  
  operator==(other) {
    if (other is! HostedSource) return false;
    return this.url == other.url && this.name == other.name;
  }
  
  int get hashCode => hash2(url, name);
}