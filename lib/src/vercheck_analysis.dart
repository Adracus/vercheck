library vercheck.analysis;

import 'dart:async' show Future;
import 'dart:math' show max; 

import 'package:pub_semver/pub_semver.dart';

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
  
  final int state;
  final List<Comparison> comparisons;
  
  Analysis._(int state, this.comparisons) : state = checkState(state);
  
  static int checkState(int state) {
    if (!states.any((s) => s == state))
      throw new ArgumentError("Invalid State $state");
    return state;
  }
  
  static Future<Analysis> analyze(Set<Dependency> dependencies) {
    return Future.wait(dependencies.map(Comparison.analyze))
                 .then((List<Comparison> comparisons) {
      int state = comparisons.fold(0, (acc, comparison) {
        if (comparison.isGood) return acc;
        if (comparison.isAny || comparison.isNonHosted)
          return max(acc, warningState);
        if (comparison.isBad) return max(acc, badState);
        if (comparison.isError) return errorState;
      });
      return new Analysis._(state, comparisons);
    });
  }
}

class Comparison {
  static const int goodState = 0;
  static const int nonHostedState = 1;
  static const int anyState = 2;
  static const int badState = 3;
  static const int errorState = 4;
  
  final Dependency dependency;
  final Package package;
  final int state;
  
  Comparison._(this.state, this.dependency, [this.package]);
  
  static Future<Comparison> analyze(Dependency dependency) {
    if (dependency.source is! HostedSource)
      return toFuture(new Comparison._(nonHostedState, dependency));
    if (dependency.version.isAny)
      return toFuture(new Comparison._(anyState, dependency));
    if (dependency.version.isEmpty)
      return toFuture(new Comparison._(badState, dependency));
    return getLatestPackage(dependency.name).then((package) {
      var state = compareVersions(dependency.version, package.version);
      return new Comparison._(state, dependency, package);
    });
  }
  
  static int compareVersions(VersionRange range, Version version) {
    if (range.allows(version)) return goodState;
    var compare = range.max.compareTo(version);
    if (0 == compare) return goodState;
    if (1 == compare) return errorState;
    return badState;
  }
  
  static Future toFuture(Object value) => new Future.value(value);
  
  bool get isBad => state == badState;
  bool get isNonHosted => state == nonHostedState;
  bool get isAny => state == anyState;
  bool get isGood => state == goodState;
  bool get isError => state == errorState;
}