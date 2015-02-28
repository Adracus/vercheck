library vercheck.dependency;

import 'package:pub_semver/pub_semver.dart' show VersionConstraint;

import 'vercheck_http.dart';
import 'vercheck_hash.dart';

class Dependency {
  final String name;
  final DependencySource source;
  
  Dependency(this.name, this.source);
  
  static Set<Dependency> dependenciesFromJson(Map<String, dynamic> dependencies) {
    var result = new Set();
    dependencies.forEach((name, json) {
      var source = new DependencySource.fromJson(name, json);
      result.add(new Dependency(name, source));
    });
    return result;
  }
  
  operator==(other) {
    if (other is! Dependency) return false;
    return this.name == other.name &&
           this.source == other.source;
  }
  
  int get hashCode => hash2(name, source);
  
  Map<String, dynamic> toJsonRepresentation() => {
    name: source.toJsonRepresentation()
  };
}

abstract class DependencySource {
  static const Map<String, String> typeNames = const {
    GitSource: "git",
    PathSource: "path",
    HostedSource: "hosted"
  };
  
  factory DependencySource.fromJson(String name, dynamic json) {
    if (json is String)
      return new HostedSource.fromJson(name, json);
    if (json is! Map<String, dynamic>)
      throw new ArgumentError.value(json);
    
    if (json.containsKey("git"))
      return new GitSource.fromJson(json["git"]);
    
    if (json.containsKey("path"))
      return new PathSource(json["path"]);
    
    if (json.containsKey("hosted")) {
      return new HostedSource.fromJson(name, json["hosted"], json["version"]);
    }
    
    throw new DependencySourceParseException(json);
  }
  
  toJsonRepresentation();
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
  
  toJsonRepresentation() {
    if (null == ref) return {"git": url.toString()};
    return {"git": {
      "url": url.toString(),
      "ref": ref
    }};
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
  
  toJsonRepresentation() {
    return {"path": path};
  }
  
  int get hashCode => path.hashCode;
}

class HostedSource implements DependencySource {
  final Uri url;
  final String name;
  final VersionConstraint version;
  
  factory HostedSource.fromJson(String name, json, [String version]) {
    if (null == version) {
      if (json is! String)
        throw new ArgumentError.value(json);
      var _version = new VersionConstraint.parse(json);
      return new HostedSource(name, _version);
    }
    if (json is! Map) throw new ArgumentError.value(json);
    var url = Uri.parse(json["url"]);
    var _name = Uri.parse(json["name"]);
    return new HostedSource(name, new VersionConstraint.parse(version), url);
  }
  
  HostedSource(this.name, this.version, [Uri url])
      : url = null == url ? defaultPubUrl : url;
  
  operator==(other) {
    if (other is! HostedSource) return false;
    return this.url == other.url && this.name == other.name;
  }
  
  toJsonRepresentation() {
    if (defaultPubUrl == url) return version.toString();
    var result = {
      "hosted": {
        "name": name,
        "url": url.toString()
      }
    };
    if (null == version) return result;
    return result..["version"] = version.toString();
  }
  
  int get hashCode => hash2(url, name);
}