import 'game.dart';
import 'position.dart';

/// PGN import/export (Seven Tag Roster plus optional extra tags). Import
/// skips comments, variations, and NAGs and stops at the first illegal move.
class Pgn {
  Pgn._();

  static String export(
    Game game, {
    Map<String, String> tags = const {},
  }) {
    final roster = <String, String>{
      'Event': 'Gambit Court game',
      'Site': 'Gambit Court',
      'Date': '????.??.??',
      'Round': '-',
      'White': 'White',
      'Black': 'Black',
      'Result': game.result?.score.replaceAll('½', '1/2') ?? '*',
    };
    roster.addAll(tags);
    if (game.start.fen != Position.startFen) {
      roster['SetUp'] = '1';
      roster['FEN'] = game.start.fen;
    }
    final buffer = StringBuffer();
    for (final entry in roster.entries) {
      final value = entry.value.replaceAll('\\', r'\\').replaceAll('"', r'\"');
      buffer.writeln('[${entry.key} "$value"]');
    }
    buffer.writeln();
    final line = StringBuffer();
    var lineLength = 0;
    void emit(String token) {
      if (lineLength + token.length + 1 > 79) {
        buffer.writeln(line.toString().trimRight());
        line.clear();
        lineLength = 0;
      }
      line.write('$token ');
      lineLength += token.length + 1;
    }

    final startsWithBlack = game.start.turn.name == 'black';
    var moveNumber = game.start.fullmoveNumber;
    for (var i = 0; i < game.moves.length; i++) {
      final isWhiteMove = startsWithBlack ? i.isOdd : i.isEven;
      if (isWhiteMove) {
        emit('$moveNumber.');
      } else if (i == 0) {
        emit('$moveNumber...');
      }
      emit(game.moves[i].san);
      if (!isWhiteMove) moveNumber++;
    }
    emit(roster['Result']!);
    buffer.writeln(line.toString().trimRight());
    return buffer.toString();
  }

  /// Parses a single PGN game. Returns null when no moves parse and there are
  /// no tags at all.
  static PgnImport? import(String text) {
    final tags = <String, String>{};
    final tagPattern = RegExp(r'\[\s*(\w+)\s+"((?:[^"\\]|\\.)*)"\s*\]');
    var rest = text;
    for (final match in tagPattern.allMatches(text)) {
      tags[match.group(1)!] =
          match.group(2)!.replaceAll(r'\"', '"').replaceAll(r'\\', '\\');
    }
    rest = rest.replaceAll(tagPattern, ' ');
    rest = _stripBraces(rest, '{', '}');
    rest = rest.replaceAll(RegExp(r';[^\n]*'), ' ');
    rest = _stripBraces(rest, '(', ')');
    rest = rest.replaceAll(RegExp(r'\$\d+'), ' ');

    Position? start;
    if (tags['FEN'] != null) {
      start = Position.fromFen(tags['FEN']!);
      if (start == null) return null;
    }
    final game = Game(start: start);
    final tokens = rest.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final errors = <String>[];
    String? resultToken;
    for (final rawToken in tokens) {
      var token = rawToken;
      if (token == '1-0' ||
          token == '0-1' ||
          token == '1/2-1/2' ||
          token == '*') {
        resultToken = token;
        break;
      }
      token = token.replaceAll(RegExp(r'^\d+\.+'), '');
      if (token.isEmpty || RegExp(r'^\.+$').hasMatch(token)) continue;
      if (game.playSan(token) == null) {
        errors
            .add('Illegal or unreadable move "$token" at ply ${game.ply + 1}');
        break;
      }
    }
    if (tags.isEmpty && game.moves.isEmpty) return null;
    return PgnImport(
        game: game, tags: tags, result: resultToken, errors: errors);
  }

  static String _stripBraces(String text, String open, String close) {
    final buffer = StringBuffer();
    var depth = 0;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (char == open) {
        depth++;
      } else if (char == close && depth > 0) {
        depth--;
        buffer.write(' ');
      } else if (depth == 0) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}

class PgnImport {
  const PgnImport({
    required this.game,
    required this.tags,
    required this.result,
    required this.errors,
  });

  final Game game;
  final Map<String, String> tags;
  final String? result;
  final List<String> errors;
}
