library vercheck.env;

import 'dart:io' show Platform;

const secret = const String.fromEnvironment("VERCHECK_SECRET");

const identifier = const String.fromEnvironment("VERCHECK_IDENTIFIER");

final authUrl = Uri.parse(const String.fromEnvironment("GITHUB_AUTH_URL",
    defaultValue: "https://github.com/login/oauth/authorize"));

final tokenUrl = Uri.parse(const String.fromEnvironment("GITHUB_TOKEN_URL",
    defaultValue: "https://github.com/login/oauth/access_token"));

final instanceUrl = Uri.parse(const String.fromEnvironment("VERCHECK_URL"));


bool checkEnv() {
  return ["VERCHECK_SECRET", "VERCHECK_IDENTIFIER",
          "GITHUB_AUTH_URL", "GITHUB_TOKEN_URL",
          "VERCHECK_URL"].every((envName) {
    if (isNull(Platform.environment[envName])) {
      throw new Exception("Env variable $envName is missing");
    }
  });
}

bool isNull(Object value) => value == null;
bool not(bool arg) => !arg;