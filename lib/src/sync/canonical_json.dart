import 'dart:convert';

/// JSON with the keys of every map sorted: the same data always gives the
/// same text — and so the same hash on every device.
class CanonicalJson {
  const CanonicalJson._();

  static String encode(Object? value) => jsonEncode(_sorted(value));

  static Object? _sorted(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => '$k').toList()..sort();
      return {for (final k in keys) k: _sorted(v[k])};
    }
    if (v is List) return [for (final e in v) _sorted(e)];
    return v;
  }
}
