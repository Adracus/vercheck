// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:github/server.dart';
import 'package:start/start.dart';

import 'cache.dart';
import 'auth.dart' as auth;
import 'env.dart' as env;
import 'middleware.dart';
import 'db.dart';
import 'analysis.dart';


void main(List<String> args) {
  initGitHub();
  
  var parser = new ArgParser()
      ..addOption('port', abbr: 'p',
          defaultsTo: "8080");

  var result = parser.parse(args);

  var port = int.parse(result['port'], onError: (val) {
    print('Could not parse port value "$val" into a number.');
    exit(1);
  });
  
  env.checkEnv();
  initializeCache();
  
  initializeDatabase().then((_) {
    start(host: '0.0.0.0', port: port).then((app) {
      app.get("/github/:owner/:repo").listen((request) {
        var slug = new RepositorySlug(request.param("owner"), request.param("repo"));
        return getAnalysis(request, slug).
            catchError((e) => packageAnalysisError(request, e));
      });
      
      app.post("/github").listen((request) {
        postAnalysis(request);
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
            request.response.deleteCookie(vercheckRedirect);
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
  });
}