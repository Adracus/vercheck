// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async' show Future, runZoned;

import 'package:vercheck/vercheck.dart';
import 'package:args/args.dart';
import 'package:start/start.dart';

import 'cache.dart';
import 'auth.dart' as auth;
import 'env.dart' as env;
import 'images.dart';
import 'middleware.dart';

Cache cache;

void main(List<String> args) {
  
  var parser = new ArgParser()
      ..addOption('port', abbr: 'p',
          defaultsTo: "8080");

  var result = parser.parse(args);

  var port = int.parse(result['port'], onError: (val) {
    stdout.writeln('Could not parse port value "$val" into a number.');
    exit(1);
  });
  
  env.checkEnv();
  
  var redis = Platform.environment["REDIS_URL"];
  cache = null == redis ? new Cache() : new RedisCache(redis);
  
  if (redis != null) print("Using redis $redis");
  
  start(host: '0.0.0.0', port: port).then((app) {
    app.get("/github/:owner/:repo").listen((request) {
      var slug = new RepoSlug(request.param("owner"), request.param("repo"));
      return _analyzePackage(request, slug).
          catchError((e) => _packageAnalysisError(request, e));
    });
    
    app.post("/github").listen((request) {
      if (!isAuthorized(request))
        return authorize(request, redirectToCurrent: true);
      jsonBody(request).then((json) {
        var client = auth.getClient(request);
        client.users.getCurrentUser().then((user) {
          if (user.login != json["user"])
            return request.response.status(401).send("Unauthorized");
          if (null == json["repo"])
            return request.response.status(400).send("Repo field missing");
          
        });
      });
    });
    
    app.get("/auth").listen((request) {
      return redirect(request, auth.authUrl);
    });
    
    app.get("/oauthcallback").listen((request) {
      var code = request.param("code");
      auth.handleCode(code).then((client) {
        request.response.cookie(vercheckToken, client.auth.token);
        
        var cookie = redirectCookie(request);
        if (null != cookie) {
          var target = Uri.decodeFull(cookie.value);
          //request.response.deleteCookie(vercheckRedirect);
          return redirect(request, target);
        }
        
        return client.users.getCurrentUser().then((user) {
          return request.response
              ..header("content-type", "text/html")
              ..send(user.name);
        });
      });
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

Future _analyzePackage(Request request, String identifier) {
  return cache.containsKey(identifier).then((contained) {
    return cache.get(identifier).then((analysis) {
      if (null != analysis) return _renderAnalysis(request, analysis);
      return getPackage(identifier).then(Analysis.analyze).then((analysis) {
        return cache.put(identifier, analysis).then((_) {
          return _renderAnalysis(request, analysis);
        });
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
