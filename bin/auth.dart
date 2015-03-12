library vercheck.auth;

import 'dart:async' show Future;

import 'package:github/server.dart';
import 'package:vercheck/vercheck.dart' show join;
import 'package:start/start.dart';

import 'env.dart' as env;
import 'middleware.dart';

Map appendToMap(Map source, Map append) {
  if (null == append) return source;
  return source..addAll(append);
}

OAuth2Flow _createClient() {
  return new OAuth2Flow(env.identifier,
                        env.secret,
                        baseUrl: env.githubAuthUrl,
                        redirectUri: _redirectUrl.toString());
}

String _authUrl;

String get authUrl {
  if (null == _authUrl) {
    _authUrl = _createClient().createAuthorizeUrl();
  }
  return _authUrl;
}

Uri get _redirectUrl => join("oauthcallback", env.instanceUrl);

Future<GitHub> handleCode(String code) {
  var client = _createClient();
  return client.exchange(code).then((response) {
    return new GitHub(auth: new Authentication.withToken(response.token));
  });
}

GitHub systemClient() {
  return new GitHub(auth: new Authentication.anonymous());
}

GitHub getClient(Request request) {
  var token = request.cookies.firstWhere((cookie) =>
      vercheckToken == cookie.name).value;
  return new GitHub(auth: new Authentication.withToken(token));
}

bool isAuthorized(Request request) {
  var cookies = request.cookies;
  return cookies.any((cookie) => vercheckToken == cookie.name);
}