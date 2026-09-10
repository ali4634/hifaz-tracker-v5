import 'dart:math';

/// Generates unique record ids.
class IdGen {
  IdGen._();

  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(0xFFFFFF).toRadixString(16)}';
}
