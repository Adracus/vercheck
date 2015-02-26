library vercheck.validator;

import 'package:pub_semver/pub_semver.dart';

import 'vercheck_dependency.dart';

class Package {
  final String name;
  final Version version;
  final String description;
  final Set<Dependency> dependencies;
  final Set<Dependency> devDependencies;
  
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
  
  bool equals(other) => equalPackages(this, other);
  
  static bool equalPackages(self, other) {
    if (other is! Package) return false;
    return self.name == other.name &&
           self.version == other.version &&
           self.description == other.description &&
           self.dependencies.difference(other.dependencies).isEmpty &&
           self.devDependencies.difference(other.devDependencies).isEmpty;
  }
}