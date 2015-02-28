library vercheck.test.package;

import 'dart:io' show File;
import 'dart:convert' show JSON;

import 'package:pub_semver/pub_semver.dart';
import 'package:unittest/unittest.dart';

import 'package:vercheck/vercheck.dart';


definePackageTests() {
  group("Package", () {
    var body = new File("res/pub_response.json").readAsStringSync();
    var rsaJson = JSON.decode(body)["latest"]["pubspec"];
    
    test("==", () {
      var d1 = new Dependency("mydep",
          new HostedSource("mydep", new Version(0, 0, 1)));
      var d2 = new Dependency("mydep",
          new PathSource("/my/path"));
      var d3 = new Dependency("mydep",
          new HostedSource("mydep", new Version(0, 0, 1)));
      
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
      
      expect(p1, equals(p1));
      expect(p1, isNot(equals(p2)));
      expect(p1, equals(p3));
      expect(p1, isNot(equals(p4)));
      expect(p1, isNot(equals(p5)));
    });
    
    test("toJsonRepresentation", () {
      var package = new Package.fromJson(rsaJson);
      
      var representation = package.toJsonRepresentation();
      expect(representation["name"], equals("rsa"));
      expect(representation["version"], equals("0.0.2"));
      expect(representation["dependencies"], equals({
        "rsa_pkcs": {
          "git": {
            "url": "git://github.com/Adracus/rsa_pkcs.git",
            "ref": "0d79fea965767a0ab6d78cf75d9101ffe49e66d7"
          }
        }, 
        "bignum": ">=0.0.6 <0.1.0",
        "bbs": ">=0.0.1 <0.1.0",
        "crypto": ">=0.9.0 <0.10.0",
        "asn1lib": {
          "git": {
            "url": "git://github.com/Adracus/asn1lib.git",
            "ref": "795eeee72b180ff106c8f6f9d48b458b049fc11f"
           }
        }
      }));
      expect(representation["dev_dependencies"],
          equals({"unittest": ">=0.11.4 <0.12.0"}));
    });
    
    test("fromJson", () {
      var package = new Package.fromJson(rsaJson);
      expect(package.name, equals("rsa"));
      expect(package.description,
          equals("A library providing a simple to use RSA interface"));
      expect(package.version, equals(new Version(0, 0, 2)));
      expect(package.dependencies.length, equals(5));
      
      var dependencies = package.dependencies.toList();
      expect(dependencies[0],
          equals(new Dependency("rsa_pkcs",
              new GitSource(Uri.parse("git://github.com/Adracus/rsa_pkcs.git"),
                            "0d79fea965767a0ab6d78cf75d9101ffe49e66d7"))));
      expect(dependencies[1],
          equals(new Dependency("bignum", new HostedSource("bignum",
              new VersionRange(
                  min: new Version(0, 0, 6),
                  max: new Version(0, 1, 0),
                  includeMin: true)))));
      expect(dependencies[2],
          equals(new Dependency("bbs", new HostedSource("bbs",
              new VersionRange(
                  min: new Version(0, 0, 1),
                  max: new Version(0, 1, 0),
                  includeMin: true)))));
      expect(dependencies[3],
          equals(new Dependency("crypto", new HostedSource("crypto",
              new VersionRange(
                  min: new Version(0, 9, 0),
                  max: new Version(0, 10, 0),
                  includeMin: true)))));
      expect(dependencies[4],
          equals(new Dependency("asn1lib",
              new GitSource(Uri.parse("git://github.com/Adracus/asn1lib.git"),
                            "795eeee72b180ff106c8f6f9d48b458b049fc11f"))));
      
      expect(package.devDependencies.length, equals(1));
      expect(package.devDependencies.single,
          equals(new Dependency("unittest", new HostedSource("unittest",
              new VersionRange(
                  min: new Version(0, 11, 4),
                  max: new Version(0, 12, 0),
                  includeMin: true)))));
    });
  });
}