library vercheck.test;

import 'vercheck_dependency_test.dart';
import 'vercheck_http_test.dart';
import 'vercheck_package_test.dart';
import 'vercheck_analysis_test.dart';


main() {
  defineDependencyTests();
  defineHttpTests();
  definePackageTests();
  defineAnalysisTests();
}