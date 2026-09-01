class JsonParsers {
  JsonParsers._();

  static String? asString(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  static String asStringOrEmpty(Object? value) {
    return asString(value) ?? '';
  }

  static int? asInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static int asIntOr(Object? value, int fallback) {
    return asInt(value) ?? fallback;
  }

  static double? asDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static double asDoubleOr(Object? value, double fallback) {
    return asDouble(value) ?? fallback;
  }

  static bool? asBool(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return null;
  }

  static List<T> asList<T>(
    Object? value,
    T? Function(Object? element) mapper,
  ) {
    if (value is! List) {
      return const [];
    }

    final result = <T>[];
    for (final element in value) {
      final mapped = mapper(element);
      if (mapped != null) {
        result.add(mapped);
      }
    }
    return result;
  }

  static Map<String, dynamic>? asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }
    return null;
  }
}
