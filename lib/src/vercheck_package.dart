library vercheck.validator;

import 'package:pub_semver/pub_semver.dart';

import 'vercheck_dependency.dart';
import 'vercheck_hash.dart';

class Package {
  final String name;
  final Version version;
  final String description;
  final Set<Dependency> dependencies;
  final Set<Dependency> devDependencies;
  int _hashCode;
  
  Package(this.name, this.version, this.description,
      this.dependencies, this.devDependencies);
  
  Package.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        version = versionFromJson(json),
        description = json["description"],
        dependencies = dependenciesFromJson(json),
        devDependencies = dependenciesFromJson(json, dev: true);
  
  static Version versionFromJson(Map<String, dynamic> json) {
    if (json.containsKey("version")) return new Version.parse(json["version"]);
    return null;
  }
  
  static Set<Dependency> dependenciesFromJson(Map<String, dynamic> json,
      {bool dev: false}) {
    var matcher = dev ? "dev_dependencies" : "dependencies";
    if (!json.containsKey(matcher)) return new Set();
    return Dependency.dependenciesFromJson(json[matcher]);
  }
  
  toJsonRepresentation() => {
    "name": name,
    "version": version.toString(),
    "dependencies": dependenciesToJsonRepresentation(),
    "dev_dependencies": dependenciesToJsonRepresentation(dev: true)
  };
  
  Map<String, dynamic> dependenciesToJsonRepresentation({bool dev: false}) {
    var deps = dev ? devDependencies : dependencies;
    return deps.fold({}, (result, dependency) {
      return result..addAll(dependency.toJsonRepresentation());
    });
  }
  
  bool operator==(other) {
    if (other is! Package) return false;
    return this.name == other.name &&
           this.version == other.version &&
           this.description == other.description &&
           this.dependencies.difference(other.dependencies).isEmpty &&
           this.devDependencies.difference(other.devDependencies).isEmpty;
  }
  
  int _dependencyHashCode({bool dev: false}) {
    var deps = dev ? devDependencies : dependencies;
    deps = deps.toList();
    deps.sort((d1, d2) => d1.name.compareTo(d2.name));
    return hashObjects(deps);
  }
  
  int get hashCode {
    if (null == _hashCode) {
      var depHash = _dependencyHashCode();
      var devDepHash = _dependencyHashCode(dev: true);
      _hashCode =
          hashObjects([name, version, description, depHash, devDepHash]);
    }
    return _hashCode;
  }
}