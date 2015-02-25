library vercheck.test.package;

import 'package:pub_semver/pub_semver.dart';
import 'package:unittest/unittest.dart';

import 'package:vercheck/vercheck.dart';


definePackageTests() {
  group("Package", () {
    test("equals", () {
      var d1 = new Dependency("mydep",
          new HostedSource("mydep"), new Version(0, 0, 1));
      var d2 = new Dependency("mydep",
          new PathSource("/my/path"), new Version(2, 0, 0));
      var d3 = new Dependency("mydep",
          new HostedSource("mydep"), new Version(0, 0, 1));
      
      var p1 = new Package("mypack", new Version(0, 1, 0), "A package",
          new Set.from([d1, d2]), new Set.from([d1]));
      
      var p2 = new Package("mypack", new Version(0, 1, 0), "Another package",
          new Set.from([d1, d2]), new Set.from([d1]));
      
      var p3 = new Package("mypack", new Version(0, 1, 0), "A package",
          new Set.from([d1, d2]), new Set.from([d1]));
      
      var p4 = new Package("mypack", new Version(1, 1, 0), "A package",
          new Set.from([d1, d2]), new Set.from([d1]));
      
      var p5 = new Package("other", new Version(0, 1, 0), "A package",
          new Set.from([]), new Set.from([d1]));
      
      expect(p1.equals(p1), isTrue);
      expect(p1.equals(p2), isFalse);
      expect(p1.equals(p3), isTrue);
      expect(p1.equals(p4), isFalse);
      expect(p1.equals(p5), isFalse);
    });
  });
}