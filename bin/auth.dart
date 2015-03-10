library vercheck.auth;

import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:vercheck/vercheck.dart' show join;

import 'env.dart';


final client = new oauth2.AuthorizationCodeGrant(identifier, secret,
      authUrl, tokenUrl);

Uri _authUri;

Uri get authUrl {
  if (_authUri == null) {
    _authUri = client.getAuthorizationUrl(join("oauthcallback", instanceUrl));
  }
  return _authUri;
}