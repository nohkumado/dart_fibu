///Operation needs to be filled, buit the way to fill is not the same in GUI or shell context
abstract class UserInteraction {
  // Method to prompt the user for an account selection
  Future<String> promptForAccountSelection(
      String message, List<String> options);

  // Method to prompt the user for text input, e.g., comment or description
  Future<String> promptForTextInput(String message, {String defaultValue = ""});

  // Method to prompt for a numerical input like a value or amount
  Future<int> promptForValueInput(String message, {int defaultValue = 0});
}
