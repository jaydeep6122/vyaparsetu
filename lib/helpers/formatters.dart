import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _indianRupeesFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  static String formatCurrency(double amount) {
    return _indianRupeesFormat.format(amount);
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date.toLocal());
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date.toLocal());
  }

  static String apiDateFormat(DateTime date) {
    return _apiDateFormat.format(date.toLocal());
  }

  static String numberToWords(int number) {
    if (number == 0) return 'Zero';
    const units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy',
      'Eighty', 'Ninety',
    ];

    String convert(int n) {
      if (n < 20) return units[n];
      if (n < 100) {
        return '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${units[n % 10]}' : ''}';
      }
      if (n < 1000) {
        return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${convert(n % 100)}' : ''}';
      }
      if (n < 100000) {
        final thousands = n ~/ 1000;
        return '${convert(thousands)} Thousand${n % 1000 != 0 ? ' ${convert(n % 1000)}' : ''}';
      }
      if (n < 10000000) {
        final lakhs = n ~/ 100000;
        return '${convert(lakhs)} Lakh${n % 100000 != 0 ? ' ${convert(n % 100000)}' : ''}';
      }
      final crores = n ~/ 10000000;
      return '${convert(crores)} Crore${n % 10000000 != 0 ? ' ${convert(n % 10000000)}' : ''}';
    }

    return convert(number);
  }
}
