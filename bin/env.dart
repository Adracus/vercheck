library vercheck.env;

import 'dart:io' show Platform;

Map get env => Platform.environment;

final secret = env["VERCHECK_SECRET"];

final identifier = env["VERCHECK_IDENTIFIER"];

final postgresUrl = env["POSTGRES_URL"];

final githubAuthUrl = fallback(env["GITHUB_AUTH_URL"],
  "https://github.com/login/oauth");

final instanceUrl = Uri.parse(fallback(env["VERCHECK_URL"], "http://localhost:8080"));



void checkEnv() {
  if (isNull(secret)) throw "VERCHECK_SECRET is missing";
  if (isNull(identifier)) throw "VERCHECK_IDENTIFIER is missing";
  if (isNull(githubAuthUrl)) throw "GITHUB_AUTH_URL is missing";
  if (isNull(instanceUrl)) throw "VERCHECK_URL is missing";
}

bool isNull(Object value) => value == null;
bool not(bool arg) => !arg;
fallback(arg, fallback) => isNull(arg) ? fallback : arg;