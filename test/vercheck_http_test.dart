library vercheck.test.http;

import 'dart:io' show File;
import 'dart:convert' show JSON;
import 'dart:async' show Future;

import 'package:http/http.dart' show Response;
import 'package:unittest/unittest.dart';

import 'package:vercheck/vercheck.dart';


defineHttpTests() {
  group("http", () {
    test("createPubUri", () {
      var url1 = createPubUri("pub.dartlang.org", prefix: "api");
      var url2 = createPubUri("my.pub.org", secure: false);
      var url3 = createPubUri("my.own.pub", prefix: "api/pub/v1", secure: false);
      
      expect(url1.toString(), equals("https://pub.dartlang.org/api"));
      expect(url2.toString(), equals("http://my.pub.org"));
      expect(url3.toString(), equals("http://my.own.pub/api/pub/v1"));
    });
    
    test("join", () {
      var url1 = Uri.parse("http://my.own.pub/api/pub/v1/");
      var url2 = Uri.parse("http://pub.dartlang.org/api");
      
      expect(join("mypackage", url1).toString(),
          equals("http://my.own.pub/api/pub/v1/mypackage"));
      expect(join("mypackage", url2).toString(),
          equals("http://pub.dartlang.org/api/mypackage"));
    });
    
    var body = new File("res/pub_response.json").readAsStringSync();
    test("getPackageJson", () {
      var getter = (url, {Map<String, String> headers}) {
        expect(url, new isInstanceOf<Uri>("Uri"));
        expect(url.toString(), equals("https://pub.dartlang.org/api/packages/rsa"));
        expect(headers, equals({"accept": "application/json"}));
        
        return new Future.value(new Response(body, 200));
      };
      getPackageJson("rsa", getter: getter).then(expectAsync((json) {
        expect(json, equals(JSON.decode(body)));
      }));
    });
    
    test("getLatestPackage", () {
      var getter = (url, {Map<String, String> headers}) {
        expect(url, new isInstanceOf<Uri>("Uri"));
        expect(url.toString(), equals("https://pub.dartlang.org/api/packages/rsa"));
        expect(headers, equals({"accept": "application/json"}));
        
        return new Future.value(new Response(body, 200));
      };
      getLatestPackage("rsa", getter: getter).then(expectAsync((Package package) {
        var compare = new Package.fromJson(JSON.decode(body)["latest"]["pubspec"]);
        
        expect(package == compare, isTrue);
      }));
    });
  });
}