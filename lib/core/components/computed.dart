import 'package:vyaparsetu/core/Core.dart';

extension CoreComputed on Core {
  double get balanceDue {
    final inv = invoice.invoices;
    double total = 0;
    for (final i in inv) {
      total += i.totalAmount - i.paidAmount;
    }
    return total;
  }
}
