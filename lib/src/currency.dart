/// Converts currency code to its corresponding symbol.
/// Supported currencies include EUR, GBP, USD, YEN, and LIR.
/// Defaults to € if the currency is unrecognized.
String cur2sym(String name) {
  String sym = "€";
  switch (name) {
    case 'EUR':
      sym = "€ ";
      break;
    case 'LIR':
      sym = "£ ";
      break;
    case 'YEN':
      sym = "¥ ";
      break;
    case 'POU':
      sym = "£ ";
      break;
    case 'DOL':
      sym = "\$ ";
      break;
    default:
      sym = "€ ";
      break;
  }
  return sym;
}
