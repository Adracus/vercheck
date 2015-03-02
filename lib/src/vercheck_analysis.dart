library vercheck.analysis;

import 'dart:async' show Future;
import 'dart:math' show max; 

import 'package:pub_semver/pub_semver.dart';

import 'vercheck_hash.dart';
import 'vercheck_dependency.dart';
import 'vercheck_package.dart';
import 'vercheck_http.dart';

class Analysis {
  static const int goodState = 0;
  static const int warningState = 1;
  static const int badState = 2;
  static const int errorState = 3;
  static const List<int> states =
      const[goodState, warningState, badState, errorState];
  
  static const Map<int, String> stateNames = const {
    goodState:    "good",
    warningState: "warning",
    badState:     "bad",
    errorState:   "error"
  };
  
  final int state;
  final Package package;
  final Set<Comparison> comparisons;
  int _hashCode;
  
  Analysis._(int state, this.package, this.comparisons)
      : state = checkState(state);
  
  Analysis.fromJson(Map<String, dynamic> json)
      : state = json["state"],
        package = new Package.fromJson(json["package"]),
        comparisons = comparisonsFromJson(json["comparisons"]);
  
  bool get isGood => goodState == state;
  bool get isWarning => warningState == state;
  bool get isBad => badState == state;
  bool get isError => errorState == state;
  
  static Set<Comparison> comparisonsFromJson(Map<String, dynamic> json) {
    var result = new Set();
    json.forEach((_, comparisonJson) {
      result.add(new Comparison.fromJson(comparisonJson));
    });
    return result;
  }
  
  static int checkState(int state) {
    if (!states.any((s) => s == state))
      throw new ArgumentError("Invalid State $state");
    return state;
  }
  
  String get stateName => stateNames[this.state];
  
  Map<String, dynamic> toJsonRepresentation() => {
    "state": state,
    "state_name": stateName,
    "package": package.toJsonRepresentation(),
    "comparisons": comparisonsJsonRepresentation()
  };
  
  Map<String, dynamic> comparisonsJsonRepresentation() {
    return comparisons.fold({}, (result, comparison) {
      result[comparison.dependency.name] = comparison.toJsonRepresentation();
      return result;
    });
  }
  
  int get hashCode {
    if (null == _hashCode) {
      var sortedComparisons = comparisons
         .toList()
         ..sort((c1, c2) =>
             c1.dependency.name.compareTo(c2.dependency.name));
      var comparisonHash = hashObjects(sortedComparisons);
      _hashCode = hash3(state, package, comparisonHash);
    }
    return _hashCode;
  }
  
  static Future<Analysis> analyze(Package package) {
    return Future.wait(package.dependencies.map(Comparison.analyze))
                 .then((List<Comparison> comparisons) {
      int state = comparisons.fold(0, (acc, comparison) {
        if (comparison.isGood) return acc;
        if (comparison.isAny || comparison.isNonHosted)
          return max(acc, warningState);
        if (comparison.isBad) return max(acc, badState);
        if (comparison.isError) return errorState;
      });
      return new Analysis._(state, package, comparisons.toSet());
    });
  }
}

class Comparison {
  static const int goodState = 0;
  static const int nonHostedState = 1;
  static const int anyState = 2;
  static const int badState = 3;
  static const int errorState = 4;
  
  static const Map<int, String> stateNames = const{
    goodState: "good",
    nonHostedState: "non-hosted",
    anyState: "any",
    badState: "bad",
    errorState: "error"
  };
  
  final Dependency dependency;
  final Package package;
  final int state;
  
  Comparison._(this.state, this.dependency, [this.package]);
  
  Comparison.fromJson(Map<String, dynamic> data)
      : dependency = new Dependency.fromJson(data["dependency"]),
        state = data["state"],
        package = null == data["package"] ?
            null : new Package.fromJson(data["package"]);
  
  String get stateName => stateNames[state];
  
  toJsonRepresentation() {
    var result = {
      "dependency": dependency.toJsonRepresentation(),
      "state": state,
      "state_name": stateName
    };
    if (null != package) result["package"] = package.toJsonRepresentation();
    return result;
  }
  
  static Future<Comparison> analyze(Dependency dependency, {Get getter}) {
    if (dependency.source is! HostedSource)
      return toFuture(new Comparison._(nonHostedState, dependency));
    return getPubPackage(dependency.name, getter: getter).then((package) {
      var version = (dependency.source as HostedSource).version;
      if (version.isEmpty)
        return toFuture(new Comparison._(badState, dependency, package));
      if (version.isAny)
        return new Comparison._(anyState, dependency, package);
      var state = compareVersions(version, package.version);
      return new Comparison._(state, dependency, package);
    });
  }
  
  static int compareVersions(VersionConstraint constraint, Version version) {
    if (constraint.isAny) return anyState;
    if (constraint.allows(version)) return goodState;
    if (constraint is VersionRange || constraint is Version) {
      var max = constraint is VersionRange ?
          constraint.max : constraint;
      var compare = max.compareTo(version);
      if (1 == compare) return errorState;
    }
    return badState;
  }
  
  static Future toFuture(Object value) => new Future.value(value);
  
  bool get isBad => state == badState;
  bool get isNonHosted => state == nonHostedState;
  bool get isAny => state == anyState;
  bool get isGood => state == goodState;
  bool get isError => state == errorState;
  
  bool operator==(other) {
    if (other is! Comparison) return false;
    return this.state == other.state &&
           this.package == other.package &&
           this.dependency == other.dependency;
  }
  
  int get hashCode => hash3(dependency, package, state);
}