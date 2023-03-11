import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../bin/cpp_comment_extractor.dart';

void main() {
  test('Test 1', () {
    var string = r"""// BEGIN

// END""";
    expect(extractComments(string).map((e) => e.content),
        equals([" BEGIN", " END"]));
  });
}
