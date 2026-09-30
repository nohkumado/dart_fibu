import 'dart:io';

import '../nohfibu.dart';

/// CLI implementation of the InputProvider
class CLIInputProvider extends InputProvider {
  @override
  String? getInput(String prompt, {String? defaultValue}) {
    print(prompt + (defaultValue != null ? ' [$defaultValue]' : ''));
    String? answer = stdin.readLineSync();
    return answer?.isEmpty ?? true ? defaultValue : answer;
  }
}
