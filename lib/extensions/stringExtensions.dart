extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((str) => str.capitalize()).join(' ');
  }

  double toDouble() {
    return double.tryParse(this) ?? 0.0;
  }
}
