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
      ..get("/packages/{name}", _analyzePackage);

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(myRouter.handler);

  io.serve(handler, 'localhost', port).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

Future<shelf.Response> _analyzePackage(shelf.Request request) {
  var packageName = getPathParameter(request, "name");
  return Analysis.analyzeLatest(packageName).then((analysis) {
    var js = JSON.encode(analysis.toJsonRepresentation());
    return new shelf.Response(200, headers: {"content-type": "json"}, body: js);
  });
}
