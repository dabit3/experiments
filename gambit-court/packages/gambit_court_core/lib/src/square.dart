/// Squares are integers 0..63 with a1 = 0, b1 = 1, ..., h8 = 63.
class Square {
  Square._();

  static const int count = 64;

  static int of(int file, int rank) => rank * 8 + file;

  static int fileOf(int square) => square & 7;

  static int rankOf(int square) => square >> 3;

  static bool isValid(int file, int rank) =>
      file >= 0 && file < 8 && rank >= 0 && rank < 8;

  static String name(int square) =>
      '${'abcdefgh'[fileOf(square)]}${rankOf(square) + 1}';

  /// Parses `e4` into a square index. Returns null for malformed input.
  static int? parse(String text) {
    if (text.length != 2) return null;
    final file = 'abcdefgh'.indexOf(text[0]);
    final rank = '12345678'.indexOf(text[1]);
    if (file < 0 || rank < 0) return null;
    return of(file, rank);
  }

  /// True when the square is dark (a1 is dark).
  static bool isDark(int square) => (fileOf(square) + rankOf(square)).isEven;
}
