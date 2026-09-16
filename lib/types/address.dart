class Address {
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;

  const Address({
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.pincode,
    this.country,
  });

  /// Null when the API sent no address.
  static Address? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    return Address(
      line1: map['line1'] as String?,
      line2: map['line2'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      pincode: map['pincode'] as String?,
      country: map['country'] as String?,
    );
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toJson() => {
    'line1': _clean(line1),
    'line2': _clean(line2),
    'city': _clean(city),
    'state': _clean(state),
    'pincode': _clean(pincode),
    'country': _clean(country),
  };

  bool get isEmpty => [
    line1,
    line2,
    city,
    state,
    pincode,
    country,
  ].every((value) => _clean(value) == null);

  /// Lines as printed on a bill: street lines, then "City, State 360001".
  List<String> get lines => [
    ?_clean(line1),
    ?_clean(line2),
    [
      _clean(city),
      [_clean(state), _clean(pincode)].whereType<String>().join(' '),
    ].whereType<String>().where((part) => part.isNotEmpty).join(', '),
    ?_clean(country),
  ].where((line) => line.isNotEmpty).toList();

  String get singleLine => lines.join(', ');
}
