library vercheck.http;

import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'package:http/http.dart' as http;

import 'vercheck_package.dart';

typedef Future<http.Response> Get(uri, {Map<String, String> headers});

final Uri defaultPubUrl =
  createApiUrl("pub.dartlang.org", prefix: "api", secure: true);

const Map<String, String> defaultHeaders =
  const {"accept": "application/json"};

Uri createApiUrl(String host, {String prefix, bool secure: true}) {
  String scheme = secure ? "https" : "http";
  return new Uri(scheme: scheme,
                 path: prefix,
                 host: host);
}

Uri query(String name, String value, Uri source) {
  var params = new Map.from(source.queryParameters);
  params[name] = value;
  return source.replace(queryParameters: params);
}

Uri join(String path, Uri source) {
  var pathSegments = source.pathSegments.toList(growable: true)
                                        ..removeWhere((str) => str.isEmpty);
  return source.replace(pathSegments: pathSegments..add(path));
}

Future<Map<String, dynamic>> getPubJson(String packageName,
    {Uri pubUrl, Map<String, String> headers: defaultHeaders,
     Get getter}) {
  if (null == pubUrl) pubUrl = defaultPubUrl;
  if (null == getter) getter = http.get;
  
  var targetUri = join(packageName, join("packages", pubUrl));
  return getter(targetUri, headers: headers).then((resp) {
    StatusException.check(200, resp);
    return JSON.decode(resp.body);
  });
}

Future<Package> getPubPackage(String packageName,
    {Uri pubUrl, Map<String, dynamic> headers: defaultHeaders,
     Get getter}) {
  return getPubJson(packageName,
                        pubUrl: pubUrl,
                        headers: headers,
                        getter: getter).then((json) {
    return new Package.fromJson(json["latest"]["pubspec"]);
  });
}

class StatusException implements Exception {
  final int expected;
  final http.Response response;
  
  StatusException(this.expected, this.response);
  
  toString() => "Expected $expected but got ${response.statusCode}";
  
  static void check(int expected, http.Response response) {
    if (expected != response.statusCode)
      throw new StatusException(expected, response);
  }
}