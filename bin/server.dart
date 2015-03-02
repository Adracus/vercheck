// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async' show Future, runZoned;

import 'package:vercheck/vercheck.dart';
import 'package:args/args.dart';
import 'package:start/start.dart';

import 'cache.dart';

Cache cache;

final errorImage = new File("packages/vercheck/status-error-lightgrey.svg")
  .readAsStringSync();
final badImage = new File("packages/vercheck/status-out--of--date-orange.svg")
  .readAsStringSync();
final warningImage = new File("packages/vercheck/status-warning-yellow.svg")
  .readAsStringSync();
final goodImage = new File("packages/vercheck/status-up--to--date-brightgreen.svg")
  .readAsStringSync();



void main(List<String> args) {
  var parser = new ArgParser()
      ..addOption('port', abbr: 'p',
          defaultsTo: "8080");

  var result = parser.parse(args);

  var port = int.parse(result['port'], onError: (val) {
    stdout.writeln('Could not parse port value "$val" into a number.');
    exit(1);
  });
  
  var redis = Platform.environment["REDIS_URL"];
  cache = null == redis ? new Cache() : new RedisCache(redis);
  
  if (redis != null) print("Using redis $redis");
  
  start(host: '0.0.0.0', port: port).then((app) {
    app.get("/packages/:name").listen((request) {
      var name = request.param("name");
      return _analyzePackage(request, name);//.
          //catchError((e) => _packageAnalysisError(request, e));
    });
    
    app.get("/github/:owner/:repo").listen((request) {
      var slug = new RepoSlug(request.param("owner"), request.param("repo"));
      return _analyzePackage(request, slug).
          catchError((e) => _packageAnalysisError(request, e));
    });
    
    app.get("/").listen((req) => req.response.send("Vercheck"));
    
    print("Server listening on $port");
  });
}

_packageAnalysisError(Request request, e) {
  print(e);
  if (e is StatusException) {
    if (404 == e.response.statusCode)
      return request.response.status(404).send("Package not found");
  }
  return request.response.status(500).send("Internal server error");
}

Future _analyzePackage(Request request, identifier) {
  return cache.get(identifier).then((analysis) {
    if (null != analysis) return _renderAnalysis(request, analysis);
    return getPackage(identifier).then(Analysis.analyze).then((analysis) {
      return cache.put(identifier, analysis).then((_) {
        return _renderAnalysis(request, analysis);
      });
    });
  });
}

_renderAnalysis(Request request, Analysis analysis) {
  var accept = request.header("accept");
  if (request.accepts("application/json"))
    return _renderJson(analysis, request);
  if (accept.any((part) => part.startsWith("image")))
    return _renderImage(analysis, request);
  return _renderHtml(analysis, request);
}

_renderHtml(Analysis analysis, Request request) {
  var path = request.path;
  return request.response
    ..status(200)
    ..header("content-type", "text/html")
    ..send('<img src="$path">');
}

_renderJson(Analysis analysis, Request request) {
  return request.response
    ..status(200)
    ..header("content-type", "application/json")
    ..json(analysis.toJsonRepresentation());
}

_renderImage(Analysis analysis, Request request) {
  var headers = {"content-type": "image/svg+xml"};
  request.response
    ..header("content-type", "image/svg+xml")
    ..status(200);
  if (analysis.isGood)
    return request.response.send(goodImage);
  if (analysis.isWarning)
    return request.response.send(warningImage);
  if (analysis.isBad)
    return request.response.send(badImage);
  return request.response.send(errorImage);
}
