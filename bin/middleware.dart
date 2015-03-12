library vercheck.middleware;

import 'dart:io' show Cookie;
import 'dart:async' show Future;
import 'dart:convert' show JSON;
import 'package:start/start.dart' show Request;

const vercheckToken = "vercheck_token";
const vercheckRedirect = "vercheck_redirect";

Future<String> body(Request request) {
  return request.input.toList().then((lines) {
    return lines.fold("", (acc, l1) => acc + new String.fromCharCodes(l1));
  });
}

Future<Map<String, dynamic>> jsonBody(Request request) {
  return body(request).then(JSON.decode);
}

void redirect(Request request, target) {
  if (target is Uri) target = target.toString();
  if (target is! String)
    throw new ArgumentError.value(target, "target", "Has to be String or Uri");
  return request.response
    .status(302)
    .header("location", target)
    .send("");
}

Cookie redirectCookie(Request request) {
  return request.cookies.firstWhere((cookie) =>
      vercheckRedirect == cookie.name,
      orElse: () => null);
}

void authorize(Request request, {bool redirectToCurrent: false, callback}) {
  if (redirectToCurrent) callback = request.uri;
  if (null != callback) {
    if (callback is Uri) callback = callback.toString();
    if (callback is! String)
      throw new ArgumentError.value(callback, "callback",
          "Has to be String or Uri");
    request.response.cookie(vercheckRedirect, Uri.encodeFull(callback));
  }
  redirect(request, "/auth");
}

bool isAuthorized(Request request) {
  var cookies = request.cookies;
  return cookies.any((cookie) => vercheckToken == cookie.name);
}
