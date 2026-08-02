import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(int amount, String symbol) {
    // If the symbol is NT$, don't add a space between symbol and number.
    // NumberFormat handles placement for us.
    final format = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 0, 
    );
    return format.format(amount);
  }
}
