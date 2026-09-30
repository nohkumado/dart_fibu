/// Abstract class to gather inputs (used for both CLI and GUI)
abstract class InputProvider {
  String? getInput(String prompt, {String? defaultValue});
}
