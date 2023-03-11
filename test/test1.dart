import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../bin/cpp_comment_extractor.dart';

void main() {
  test('Test 1', () {
    var string = r"""/**/
/* a */
/* あ */
/* 文 */
/***/
/*
*/
/*//*/
/*
//
*/

//
// a
// あ
// 文
///
///*
//*/
// /*
// */

int main() {
  '//';
  '/**/';
  '\'/**/';
  '\\' /**/;
  '\
  ';

  "//";
  "/**/";
  "\"/**/";
  "\\" /**/;
  "\
  ";

  R"(
    //
  )";
  R"(
    /**/
  )";
}""";
    expect(
        extractComments(string).map((e) => e.content),
        equals([
          "",
          " a ",
          " あ ",
          " 文 ",
          "*",
          "\n",
          "//",
          "\n//\n",
          "",
          " a",
          " あ",
          " 文",
          "/",
          "/*",
          "*/",
          " /*",
          " */",
          "",
          ""
        ]));
  });
}
