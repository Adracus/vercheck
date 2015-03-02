library vercheck.http;

import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart' show loadYaml;

import 'vercheck_package.dart';
import 'vercheck_hash.dart';

typedef Future<http.Response> Get(uri, {Map<String, String> headers});

final Uri defaultPubUrl =
  createApiUrl("pub.dartlang.org", prefix: "api", secure: true);
final Uri defaultGithubUrl =
  createApiUrl("api.github.com", secure: true);

const Map<String, String> defaultHeaders =
  const {"accept": "application/json"};
  
class RepoSlug {
  final String owner;
  final String repo;
  
  RepoSlug(this.owner, this.repo);
  
  operator==(other) {
    if (other is! RepoSlug) return false;
    return other.owner == this.owner && other.repo == this.repo;
  }
  
  int get hashCode => hash2(owner, repo);
}

Uri createApiUrl(String host, {String prefix, bool secure: true}) {
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

Future<Package> getPackage(identifier,
    {Uri idUrl, Map<String, dynamic> headers: defaultHeaders, Get getter}) {
  if (identifier is! String && identifier is! RepoSlug)
    throw new ArgumentError.value(identifier);
  if (identifier is String)
    return getPubPackage(identifier,
        pubUrl: idUrl,
        headers: headers,
        getter: getter);
  return getGithubPackage(identifier, 
      githubUrl: idUrl,
      headers: headers,
      getter: getter);
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

Future<String> getGitJson(RepoSlug slug, String path,
    {Uri githubUrl, Map<String, dynamic> headers: defaultHeaders,
      Get getter}) {
  if (null == githubUrl) githubUrl = defaultGithubUrl;
  if (null == getter) getter = http.get;
  
  var targetUri = join(path,
                  join("contents",
                  join(slug.repo,
                  join(slug.owner,
                  join("repos",
                    githubUrl)))));
  
  return getter(targetUri, headers: headers).then((response) {
    var data = JSON.decode(response.body);
    var downloadUrl = data["download_url"];
    return getter(downloadUrl).then((response) => response.body);
  });
}

Future<Package> getGithubPackage(RepoSlug slug,
    {Uri githubUrl, Map<String, dynamic> headers: defaultHeaders,
      Get getter}) {
  return getGitJson(slug, "pubspec.yaml",
      getter: getter,
      headers: headers,
      githubUrl: githubUrl).then((content) {
    var data = loadYaml(content);
    return new Package.fromJson(data);
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