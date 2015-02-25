library vercheck.test.depencency;

import 'package:unittest/unittest.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:vercheck/vercheck.dart';


defineDependencyTests() {
  group("Dependency", () {
    group("DependencySource", () {
      group("HostedSource", () {
        test("==", () {
          var h1 = new HostedSource("mypackage");
          var h2 = new HostedSource("mypackage",
              Uri.parse("http://www.example.org"));
          var h3 = new HostedSource("other");
          var h4 = new HostedSource("mypackage");
          
          expect(h1, equals(h1));
          expect(h1, isNot(equals(h2)));
          expect(h2, isNot(equals(h3)));
          expect(h4, equals(h1));
          expect(h1.hashCode, equals(h4.hashCode));
        });
      });
      
      group("PathSource", () {
        test("==", () {
          var p1 = new PathSource("/my/path");
          var p2 = new PathSource("/other/path");
          var p3 = new PathSource("/my/path");
          
          expect(p1, equals(p1));
          expect(p1, isNot(equals(p2)));
          expect(p1, equals(p3));
          expect(p1.hashCode, equals(p3.hashCode));
        });
      });
      
      group("GitSource", () {
        test("==", () {
          var g1 = new GitSource(Uri.parse("http://example.org"));
          var g2 = new GitSource(Uri.parse("http://example.org"), "myref");
          var g3 = new GitSource(Uri.parse("http://example.org/other"));
          var g4 = new GitSource(Uri.parse("http://example.org"));
          
          expect(g1, equals(g1));
          expect(g1, isNot(equals(g2)));
          expect(g1, isNot(equals(g3)));
          expect(g1, equals(g4));
          expect(g1.hashCode, equals(g4.hashCode));
        });
      });
    });
    
    group("Dependency", () {
      test("==", () {
        var d1 = new Dependency("mydep",
            new HostedSource("mydep"), new Version(0, 0, 1));
        var d2 = new Dependency("mydep",
            new PathSource("/my/path"), new Version(2, 0, 0));
        var d3 = new Dependency("mydep",
            new HostedSource("mydep"), new Version(0, 0, 1));
        
        expect(d1, equals(d1));
        expect(d1, isNot(equals(d2)));
        expect(d1, equals(d3));
        expect(d1.hashCode, equals(d3.hashCode));
      });
    });
  });
}