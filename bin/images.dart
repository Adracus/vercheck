library vercheck.images;

import 'dart:io' show File;

final errorImage = new File("packages/vercheck/status-error-lightgrey.svg")
  .readAsStringSync();
final badImage = new File("packages/vercheck/status-out--of--date-orange.svg")
  .readAsStringSync();
final warningImage = new File("packages/vercheck/status-warning-yellow.svg")
  .readAsStringSync();
final goodImage = new File("packages/vercheck/status-up--to--date-brightgreen.svg")
  .readAsStringSync();