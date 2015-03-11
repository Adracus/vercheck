library vercheck.auth;

import 'dart:async' show Future;

import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:vercheck/vercheck.dart' show join;

import 'env.dart';




oauth2.AuthorizationCodeGrant _createClient() {
  return new oauth2.AuthorizationCodeGrant(identifier, secret,
        githubAuthUrl, githubTokenUrl);
}

Uri _authUrl;

Uri get authUrl {
  if (null == _authUrl) {
    _authUrl = _createClient().getAuthorizationUrl(_redirectUrl);
  }
  return _authUrl;
}

Uri get _redirectUrl => join("oauthcallback", instanceUrl);

Future<oauth2.Client> handleAuthorization(Map<String, String> parameters) {
  var client = _createClient();
  client.getAuthorizationUrl(_redirectUrl);
  return client.handleAuthorizationResponse(parameters);
}