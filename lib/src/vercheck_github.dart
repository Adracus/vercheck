library vercheck.github;

import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'package:github/server.dart';
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;

import 'vercheck_package.dart';
import 'vercheck_http.dart';

final Uri defaultGithubUrl =
  createApiUrl("api.github.com", secure: true);

Uri addAuth(String identifier, String secret, Uri source) {
  return query("client_id", identifier,
         query("client_secret", secret, source));
}

Future<RepositorySlug> slugFromId(int id,
    {Uri githubUrl, Map<String, dynamic> headers: defaultHeaders,
      Get getter, String secret, String identifier}) {
  if (null == githubUrl) githubUrl = defaultGithubUrl;
  if (null == getter) getter = http.get;
  
  var targetUri = join(id.toString(), join("repositories", githubUrl));
  
  if (null != secret && null != identifier) {
    targetUri = addAuth(identifier, secret, targetUri);
  }
  
  return getter(targetUri, headers: headers).then((response) {
    StatusException.check(200, response);
    
    var data = JSON.decode(response.body);
    var fullName = data["full_name"];
    return new RepositorySlug.full(fullName);
  });
}

Future<int> idFromSlug(RepositorySlug slug,
    {Uri githubUrl, Map<String, dynamic> headers: defaultHeaders,
      Get getter, String secret, String identifier}) {
  if (null == githubUrl) githubUrl = defaultGithubUrl;
  if (null == getter) getter = http.get;
  
  var targetUri = join(slug.name, join(slug.owner, join("repos", githubUrl)));
  
  if (null != secret && null != identifier) {
    targetUri = addAuth(identifier, secret, targetUri);
  }
  
  return getter(targetUri, headers: headers).then((response) {
    StatusException.check(200, response);
    
    var data = JSON.decode(response.body);
    var id = data["id"];
    return id;
  });
}

Future<String> getGitJson(RepositorySlug slug, String path,
    {Uri githubUrl, Map<String, dynamic> headers: defaultHeaders,
      Get getter, String secret, String identifier}) {
  if (null == githubUrl) githubUrl = defaultGithubUrl;
  if (null == getter) getter = http.get;
  
  var targetUri = join(path,
                  join("contents",
                  join(slug.name,
                  join(slug.owner,
                  join("repos",
                    githubUrl)))));
  
  if (null != secret && null != identifier) {
    targetUri = addAuth(identifier, secret, targetUri);
  }
  
  return getter(targetUri, headers: headers).then((response) {
    StatusException.check(200, response);
    
    var data = JSON.decode(response.body);
    var downloadUrl = data["download_url"];
    return getter(downloadUrl).then((response) => response.body);
  });
}

Future<Package> getGithubPackage(RepositorySlug slug,
    {Uri githubUrl, Map<String, dynamic> headers: defaultHeaders,
      Get getter, String secret, String identifier}) {
  return getGitJson(slug, "pubspec.yaml",
      getter: getter,
      headers: headers,
      githubUrl: githubUrl,
      secret: secret,
      identifier: identifier).then((content) {
    var data = loadYaml(content);
    return new Package.fromJson(data);
  });
}