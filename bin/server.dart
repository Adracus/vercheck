// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async' show Future;
import 'dart:convert' show JSON;

import 'package:vercheck/vercheck.dart';
import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';

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
  
  var myRouter = router()
      ..get("/packages/{name}", _getPackage);

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(myRouter.handler);

  io.serve(handler, 'localhost', port).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

Future<Analysis> _analyze(shelf.Request request) {
  var packageName = getPathParameter(request, "name");
  if (analyses.containsKey(packageName))
    return new Future.value(analyses[packageName]);
  return Analysis.analyzeLatest(packageName).then((analysis) {
    return analyses[packageName] = analysis;
  });
}

Future<shelf.Response> _getPackage(shelf.Request request) {
  var accept = request.headers["accept"];
  return _analyze(request).then((analysis) {
    if ("application/json" == accept)
      return _renderJson(analysis, request);
    if (accept.startsWith("image"))
      return _renderImage(analysis, request);
    return _renderHtml(analysis, request);
  });
}

shelf.Response _renderHtml(Analysis analysis, shelf.Request request) {
  var name = getPathParameter(request, "name");
  return new shelf.Response(200,
      body: '<img src="http://localhost:8080/packages/$name">',
      headers: {
        "content-type": "text/html"
      }
  );
}

shelf.Response _renderJson(Analysis analysis, shelf.Request request) {
  var json = JSON.encode(analysis.toJsonRepresentation());
  var response = new shelf.Response(200,
      body: json,
      headers: {
        "content-type": "application/json"
      }
  );
  return response;
}

shelf.Response _renderImage(Analysis analysis, shelf.Request request) {
  var headers = {"content-type": "image/svg+xml"};
  if (analysis.isGood)
    return new shelf.Response(200, body: goodImage, headers: headers);
  if (analysis.isWarning)
    return new shelf.Response(200, body: warningImage, headers: headers);
  if (analysis.isBad)
    return new shelf.Response(200, body: badImage, headers: headers);
  return new shelf.Response(200, body: errorImage, headers: headers);
}
