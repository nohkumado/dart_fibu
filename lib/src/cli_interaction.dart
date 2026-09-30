import 'dart:io';

import '../nohfibu.dart';

/// The default implementation of `UserInteraction`on CLI level
class CLIInteraction implements UserInteraction {
  @override
  Future<String> promptForAccountSelection(
      String message, List<String> options) async {
    print(message);
    for (int i = 0; i < options.length; i++) {
      print("${i + 1}. ${options[i]}");
    }

    // Read user's selection and validate input
    int choice = -1;
    while (choice < 1 || choice > options.length) {
      stdout.write("Enter choice [1-${options.length}]: ");
      choice = int.parse(stdin.readLineSync()!);
    }

    return options[choice - 1];
  }

  @override
  Future<String> promptForTextInput(String message,
      {String defaultValue = ""}) async {
    stdout.write("$message (default: $defaultValue): ");
    String input = stdin.readLineSync()!;
    return input.isNotEmpty ? input : defaultValue;
  }

  @override
  Future<int> promptForValueInput(String message,
      {int defaultValue = 0}) async {
    stdout.write("$message (default: $defaultValue): ");
    String input = stdin.readLineSync()!;
    return input.isNotEmpty ? int.parse(input) : defaultValue;
  }
}
