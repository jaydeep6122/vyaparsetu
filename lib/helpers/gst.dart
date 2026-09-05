/// GST place-of-supply helpers.
///
/// Indian GST splits tax by where the supply lands:
///
/// * **Intra-state** (buyer and seller in the same state) - CGST + SGST, each
///   at half the total rate.
/// * **Inter-state** (different states) - a single IGST line at the full rate.
///
/// The app previously printed CGST + SGST on every invoice by halving the tax
/// amount, and hard-coded the place of supply to the seller's own state, so
/// every inter-state invoice was wrong.
library;

/// The first two digits of a GSTIN are the state code.
const Map<String, String> _gstStateCodes = {
  '01': 'Jammu and Kashmir',
  '02': 'Himachal Pradesh',
  '03': 'Punjab',
  '04': 'Chandigarh',
  '05': 'Uttarakhand',
  '06': 'Haryana',
  '07': 'Delhi',
  '08': 'Rajasthan',
  '09': 'Uttar Pradesh',
  '10': 'Bihar',
  '11': 'Sikkim',
  '12': 'Arunachal Pradesh',
  '13': 'Nagaland',
  '14': 'Manipur',
  '15': 'Mizoram',
  '16': 'Tripura',
  '17': 'Meghalaya',
  '18': 'Assam',
  '19': 'West Bengal',
  '20': 'Jharkhand',
  '21': 'Odisha',
  '22': 'Chhattisgarh',
  '23': 'Madhya Pradesh',
  '24': 'Gujarat',
  '25': 'Daman and Diu',
  '26': 'Dadra and Nagar Haveli and Daman and Diu',
  '27': 'Maharashtra',
  '28': 'Andhra Pradesh',
  '29': 'Karnataka',
  '30': 'Goa',
  '31': 'Lakshadweep',
  '32': 'Kerala',
  '33': 'Tamil Nadu',
  '34': 'Puducherry',
  '35': 'Andaman and Nicobar Islands',
  '36': 'Telangana',
  '37': 'Andhra Pradesh',
  '38': 'Ladakh',
  '97': 'Other Territory',
};

/// Alternate spellings seen in free-text state fields.
///
/// Keys must already be in normalised form (lower case, `&` spelled "and",
/// punctuation stripped) because the lookup happens after normalising.
const Map<String, String> _stateAliases = {
  'orissa': 'odisha',
  'pondicherry': 'puducherry',
  'uttaranchal': 'uttarakhand',
  'nct of delhi': 'delhi',
  'new delhi': 'delhi',
  'delhi ncr': 'delhi',
  'tamilnadu': 'tamil nadu',
  'dadra and nagar haveli': 'dadra and nagar haveli and daman and diu',
};

String _normalise(String value) {
  var s = value.trim().toLowerCase().replaceAll('&', 'and');
  s = s.replaceAll(RegExp(r'[^a-z ]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return _stateAliases[s] ?? s;
}

/// Names indexed by their normalised form, built once.
final Map<String, String> _codeByStateName = {
  for (final entry in _gstStateCodes.entries)
    // 28/37 both map to Andhra Pradesh; the later (37, current) wins, which is
    // the right default for new registrations.
    _normalise(entry.value): entry.key,
};

/// State code from a GSTIN, or null if it doesn't look like one.
String? stateCodeFromGstin(String? gstin) {
  if (gstin == null) return null;
  final trimmed = gstin.trim();
  if (trimmed.length < 2) return null;
  final prefix = trimmed.substring(0, 2);
  if (!RegExp(r'^\d{2}$').hasMatch(prefix)) return null;
  return _gstStateCodes.containsKey(prefix) ? prefix : null;
}

/// State code from a free-text state name, or null if unrecognised.
String? stateCodeFromName(String? state) {
  if (state == null || state.trim().isEmpty) return null;
  return _codeByStateName[_normalise(state)];
}

/// Best available state code: GSTIN first (authoritative), then the name.
String? resolveStateCode({String? gstin, String? stateName}) {
  return stateCodeFromGstin(gstin) ?? stateCodeFromName(stateName);
}

/// The state name for a code, for printing place of supply.
String? stateNameFromCode(String? code) =>
    code == null ? null : _gstStateCodes[code];

/// Whether a supply from [sellerCode] to [buyerCode] crosses a state border.
///
/// Returns false when either side is unknown. That deliberately keeps the
/// pre-existing CGST + SGST behaviour for parties recorded before the state
/// field existed, rather than silently switching them to IGST.
bool isInterStateSupply({String? sellerCode, String? buyerCode}) {
  if (sellerCode == null || buyerCode == null) return false;
  return sellerCode != buyerCode;
}

/// How a tax amount breaks down on an invoice.
///
/// Intra-state splits into equal CGST and SGST halves; inter-state is a single
/// IGST line at the full rate. Use [amounts] for document totals and
/// [ofRate] for a per-line rate breakdown.
class GstSplit {
  /// True when the supply crosses a state border (IGST applies).
  final bool isInterState;

  /// Total tax rate as a percentage (e.g. 18 for 18%).
  final double rate;

  /// Total tax in currency.
  final double amount;

  const GstSplit({
    required this.isInterState,
    required this.rate,
    required this.amount,
  });

  /// Split for a document total.
  factory GstSplit.amounts({
    required bool isInterState,
    required double subTotal,
    required double taxAmount,
  }) {
    final rate = (subTotal > 0 && taxAmount > 0)
        ? (taxAmount / subTotal) * 100
        : 0.0;
    return GstSplit(
      isInterState: isInterState,
      rate: rate,
      amount: taxAmount,
    );
  }

  /// Split for a single line's rate, where the amount is not needed.
  factory GstSplit.ofRate({
    required bool isInterState,
    required double rate,
    double amount = 0,
  }) {
    return GstSplit(isInterState: isInterState, rate: rate, amount: amount);
  }

  double get cgstRate => isInterState ? 0 : rate / 2;
  double get sgstRate => isInterState ? 0 : rate / 2;
  double get igstRate => isInterState ? rate : 0;

  double get cgstAmount => isInterState ? 0 : amount / 2;
  double get sgstAmount => isInterState ? 0 : amount / 2;
  double get igstAmount => isInterState ? amount : 0;
}
