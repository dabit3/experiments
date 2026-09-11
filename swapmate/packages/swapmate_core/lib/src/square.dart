/// Squares are indexed 0..63 with a1 = 0, b1 = 1, ..., h8 = 63.
class Square {
  Square._();

  static const files = 'abcdefgh';

  static int of(int file, int rank) => rank * 8 + file;

  static int fileOf(int sq) => sq & 7;

  static int rankOf(int sq) => sq >> 3;

  static bool valid(int file, int rank) =>
      file >= 0 && file < 8 && rank >= 0 && rank < 8;

  /// Algebraic name such as `e4`.
  static String name(int sq) => '${files[fileOf(sq)]}${rankOf(sq) + 1}';

  static int parse(String name) {
    final file = files.indexOf(name[0]);
    final rank = int.parse(name[1]) - 1;
    if (file < 0 || rank < 0 || rank > 7) {
      throw FormatException('bad square $name');
    }
    return of(file, rank);
  }

  static bool isLight(int sq) => (fileOf(sq) + rankOf(sq)).isOdd;
}
