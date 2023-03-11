import 'dart:io';

import 'package:string_scanner/string_scanner.dart';
import 'package:args/args.dart';

var parser = ArgParser();

enum CommentType {
  block,
  line,
}

enum LiteralType {
  char,
  string,
  rawString,
}

class Comment {
  String content;
  CommentType type;
  int position;

  Comment(this.type, this.content, this.position);

  @override
  String toString() {
    return "{type: $type, content: \"$content\", position: $position}";
  }
}

List<Comment> extractComments(String source) {
  var extractor = _CommentExtractor(source);
  return extractor.extractComments();
}

class _CommentExtractor {
  String source;
  StringScanner scanner;
  List<Comment> comments = [];
  Comment? inComment;
  LiteralType? inLiteral;

  _CommentExtractor(this.source) : scanner = StringScanner(source);

  void consumeChar() {
    scanner.readChar();
  }

  void consumeCommentChar() {
    var readChar = scanner.readChar();
    inComment!.content += String.fromCharCode(readChar);
  }

  // Consume CR+LF, LF or CR line break
  bool scanLineBreak() {
    return scanner.scan("\r\n") || scanner.scan("\n") || scanner.scan("\r");
  }

  get isInBlockComment =>
      inComment != null && inComment?.type == CommentType.block;

  get isInLineComment =>
      inComment != null && inComment?.type == CommentType.line;

  void beginCommentBlock(int position) {
    inComment = Comment(CommentType.block, "", position);
  }

  void beginCommentLine(int position) {
    inComment = Comment(CommentType.line, "", position);
  }

  void endComment() {
    if (inComment != null) {
      comments.add(inComment!);
      inComment = null;
    }
  }

  get isInCharLiteral => inLiteral == LiteralType.char;

  get isInStringLiteral => inLiteral == LiteralType.string;

  get isInRawStringLiteral => inLiteral == LiteralType.rawString;

  void beginCharLiteral() {
    inLiteral = LiteralType.char;
  }

  void beginStringLiteral() {
    inLiteral = LiteralType.string;
  }

  void beginRawStringLiteral() {
    inLiteral = LiteralType.rawString;
  }

  void endLiteral() {
    inLiteral = null;
  }

  List<Comment> extractComments() {
    comments = [];

    while (!scanner.isDone) {
      if (isInBlockComment) {
        if (scanner.scan("*/")) {
          endComment();
        } else {
          consumeCommentChar();
        }
      } else if (isInLineComment) {
        if (scanLineBreak()) {
          endComment();
        } else {
          consumeCommentChar();
        }
      } else if (isInCharLiteral) {
        if (scanner.scan(r"\\")) {
          // Ignore
        } else if (scanner.scan(r"\'")) {
          // Ignore
        } else if (scanner.scan("'")) {
          endLiteral();
        } else {
          consumeChar();
        }
      } else if (isInStringLiteral) {
        if (scanner.scan(r"\\")) {
          // Ignore
        } else if (scanner.scan(r'\"')) {
          // Ignore
        } else if (scanner.scan('"')) {
          endLiteral();
        } else {
          consumeChar();
        }
      } else if (isInRawStringLiteral) {
        if (scanner.scan(')"')) {
          endLiteral();
        } else {
          consumeChar();
        }
      } else {
        var position = scanner.position;

        if (scanner.scan("//")) {
          beginCommentLine(position);
        } else if (scanner.scan("/*")) {
          beginCommentBlock(position);
        } else if (scanner.scan("*/")) {
          endComment();
        } else if (scanner.scan("'")) {
          beginCharLiteral();
        } else if (scanner.scan('"')) {
          beginStringLiteral();
        } else if (scanner.scan('R"(')) {
          beginRawStringLiteral();
        } else {
          consumeChar();
        }
      }
    }

    endComment();
    return comments;
  }
}

void showUsage() {
  print("USAGE: cpp_comment_extractor <source-file>");
  // print("OPTIONS:");
  // print(parser.usage);
}

Future<void> main(List<String> arguments) async {
  var results = parser.parse(arguments);

  if (results.rest.isEmpty) {
    showUsage();
    exit(1);
  }

  final filePath = arguments[0];
  final file = File(filePath);
  final source = await file.readAsString();
  print(extractComments(source));
}
