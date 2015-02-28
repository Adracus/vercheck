// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async' show Future, runZoned;

import 'package:vercheck/vercheck.dart';
import 'package:args/args.dart';
import 'package:start/start.dart';

final errorImage = new File("packages/vercheck/status-error-lightgrey.svg")
  .readAsStringSync();
final badImage = new File("packages/vercheck/status-out--of--date-orange.svg")
  .readAsStringSync();
final warningImage = new File("packages/vercheck/status-warning-yellow.svg")
  .readAsStringSync();
final goodImage = new File("packages/vercheck/status-up--to--date-brightgreen.svg")
  .readAsStringSync();

Map<String, Analysis> analyses = {};

void main(List<String> args) {
  var parser = new ArgParser()
      ..addOption('port', abbr: 'p',
          defaultsTo: const String.fromEnvironment("port",
              defaultValue: "8080"));

  var result = parser.parse(args);

  var port = int.parse(result['port'], onError: (val) {
    stdout.writeln('Could not parse port value "$val" into a number.');
    exit(1);
  });
  
  start(port: port).then((app) {
    app.get("/packages/:name").listen(_getPackage);
    
    print("Server listening on $port");
  });
}

Future<Analysis> _analyze(Request request) {
  var packageName = request.param("name");
  if (analyses.containsKey(packageName))
    return new Future.value(analyses[packageName]);
  return Analysis.analyzeLatest(packageName).then((analysis) {
    return analyses[packageName] = analysis;
  }).catchError((e) {
    print(e);
    request.response
      .status(500)
      .send("Internal server error");
  });
}

_getPackage(Request request) {
  var accept = request.header("accept");
  return _analyze(request).then((analysis) {
    if (request.accepts("application/json"))
      return _renderJson(analysis, request);
    if (accept.any((part) => part.startsWith("image")))
      return _renderImage(analysis, request);
    return _renderHtml(analysis, request);
  });
}

_renderHtml(Analysis analysis, Request request) {
  var name = request.param("name");
  return request.response
    ..status(200)
    ..header("content-type", "text/html")
    ..send('<img src="http://localhost:8080/packages/$name">');
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
