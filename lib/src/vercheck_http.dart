library vercheck.http;

import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'package:http/http.dart' as http;

final Uri defaultPubUrl =
  createPubUri("pub.dartlang.org", prefix: "api", secure: false);

const Map<String, String> defaultHeaders =
  const {"accept": "application/json"};

Uri createPubUri(String host, {String prefix, bool secure: true}) {
  String scheme = secure ? "https" : "http";
  return new Uri(scheme: scheme,
                 path: prefix,
                 host: host);
}

Uri join(String path, Uri source) {
  var pathSegments = source.pathSegments.toList(growable: true)
                                        ..removeWhere((str) => str.isEmpty);
  return source.replace(pathSegments: pathSegments..add(path));
}

Future<Map<String, dynamic>> getPackageJson(String packageName,
    {Uri pubUrl, Map<String, String> headers: defaultHeaders}) {
  if (null == pubUrl) pubUrl = defaultPubUrl;
  
  var targetUri = join(packageName, join("packages", pubUrl));
  return http.get(targetUri, headers: headers).then((resp) {
    StatusException.check(200, resp);
    return JSON.decode(resp.body);
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