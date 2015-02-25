library vercheck.test.analysis;

import 'dart:io' show File;
import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'package:http/http.dart' show Response;
import 'package:pub_semver/pub_semver.dart';
import 'package:unittest/unittest.dart';
import 'package:vercheck/vercheck.dart';


defineAnalysisTests() {
  group("Analysis", () {
    group("Analysis", () {
    });
    
    group("Comparison", () {
      group("analyze", () {
        test("non hosted sources", () {
          void _compare(DependencySource source) {
            Comparison.analyze(new Dependency("mydep",source))
                      .then(expectAsync((comparison) {
              expect(comparison.package, isNull);
              expect(comparison.isNonHosted, isTrue);
            }));
          }
          _compare(new PathSource("/my/path"));
          _compare(new GitSource(Uri.parse("http://www.example.org")));
        });
        
        var rsaResponse = new File("res/pub_response.json")
                                      .readAsStringSync();
        
        var rsaGetter = (url, {Map<String, String> headers}) {
          return new Future.value(new Response(rsaResponse, 200));
        };
        
        test("any constraint", () {
          var rsaResponse = new File("res/pub_response.json")
                                        .readAsStringSync();
          
          var dep = new Dependency("rsa",
              new HostedSource("rsa"), VersionConstraint.any);
          
          Comparison.analyze(dep, getter: rsaGetter).then(expectAsync((comparison) {
            expect(comparison.package.equals(
                new Package.fromJson(JSON.decode(rsaResponse)["latest"]["pubspec"])),
                isTrue);
            expect(comparison.isAny, isTrue);
          }));
        });
        
        test("hosted sources", () {
          void _compare(VersionConstraint version, int expectedState) {
            var dep = new Dependency("rsa", new HostedSource("rsa"), version);
            
            Comparison.analyze(dep, getter: rsaGetter).then(expectAsync((comparison) {
              expect(comparison.package.equals(
                  new Package.fromJson(JSON.decode(rsaResponse)["latest"]["pubspec"])),
                  isTrue);
              expect(comparison.state, equals(expectedState));
            }));
          }
          
          _compare(new Version(0, 0, 2), Comparison.goodState);
          _compare(new VersionRange(min: new Version(0, 0, 2),
                                    max: new Version(0, 1, 0),
                                    includeMin: true),
                                        Comparison.goodState);
          _compare(VersionConstraint.any, Comparison.anyState);
          _compare(new Version(0, 0, 1), Comparison.badState);
          _compare(new Version(0, 0, 3), Comparison.errorState);
          _compare(VersionConstraint.empty, Comparison.badState);
        });
      });
      
      group("compareVersions", () {
        test("Version range with Version", () {
          var range = new VersionRange(min: new Version(0, 0, 3), // >0.0.3 < 0.1.0
                                       max: new Version(0, 1, 0),
                                       includeMax: false);
          
          var v1 = new Version(0, 0, 10);
          var v2 = new Version(0, 1, 0);
          var v3 = new Version(1, 0, 0);
          var v4 = new Version(0, 0, 3);
          
          expect(Comparison.compareVersions(range, v1),
              equals(Comparison.goodState));
          expect(Comparison.compareVersions(range, v2),
              equals(Comparison.badState));
          expect(Comparison.compareVersions(range, v3),
              equals(Comparison.badState));
          expect(Comparison.compareVersions(range, v4),
              equals(Comparison.errorState));
        });
        
        test("Version with Version", () {
          var constraint = new Version(1, 3, 1);
          
          var v1 = new Version(1, 3, 1);
          var v2 = new Version(0, 0, 1);
          var v3 = new Version(1, 3, 2);
          
          expect(Comparison.compareVersions(constraint, v1),
              equals(Comparison.goodState));
          expect(Comparison.compareVersions(constraint, v2),
              equals(Comparison.errorState));
          expect(Comparison.compareVersions(constraint, v3),
              equals(Comparison.badState));
        });
        
        test("Any constraint", () {
          var constraint = VersionConstraint.any;
          
          var v = new Version(0, 12, 3);
          expect(Comparison.compareVersions(constraint, v),
              equals(Comparison.anyState));
        });
      });
    });
  });
}