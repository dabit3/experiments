import 'match.dart';
import 'piece.dart';

/// Bughouse Portable Game Notation export.
///
/// Follows the FICS/BPGN conventions: one `[Tag "value"]` per line, then the
/// moves in chronological order across both boards, numbered per board with
/// `A`/`a` for board A white/black and `B`/`b` for board B, each followed by
/// the mover's remaining clock in seconds, and finally a result comment and
/// the result token.
class Bpgn {
  Bpgn._();

  static String export({
    required BughouseMatch match,
    required Map<Seat, String> names,
    required DateTime date,
    String event = 'Swapmate match',
    String site = 'Swapmate',
  }) {
    final buf = StringBuffer();
    String tag(String k, String v) => '[$k "${v.replaceAll('"', "'")}"]';
    buf.writeln(tag('Event', event));
    buf.writeln(tag('Site', site));
    buf.writeln(tag('Date', _date(date)));
    buf.writeln(tag('WhiteA', names[Seat.aWhite] ?? '?'));
    buf.writeln(tag('BlackA', names[Seat.aBlack] ?? '?'));
    buf.writeln(tag('WhiteB', names[Seat.bWhite] ?? '?'));
    buf.writeln(tag('BlackB', names[Seat.bBlack] ?? '?'));
    buf.writeln(tag('TimeControl', match.timeControl.pgn));
    buf.writeln(tag('Variant', 'bughouse'));
    buf.writeln(tag('Result', match.result?.pgn ?? '*'));
    buf.writeln();

    final tokens = <String>[];
    for (final m in match.history) {
      tokens.add('${m.bpgn} {${_seconds(m.clockMs)}}');
    }
    final r = match.result;
    if (r != null) {
      tokens.add('{${resultComment(r)}} ${r.pgn}');
    } else {
      tokens.add('*');
    }
    // Wrap at ~78 columns like PGN.
    var line = StringBuffer();
    for (final t in tokens) {
      if (line.isNotEmpty && line.length + t.length + 1 > 78) {
        buf.writeln(line);
        line = StringBuffer();
      }
      if (line.isNotEmpty) line.write(' ');
      line.write(t);
    }
    if (line.isNotEmpty) buf.writeln(line);
    return buf.toString();
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  static String _seconds(int ms) {
    if (ms % 1000 == 0) return '${ms ~/ 1000}';
    final s = (ms / 1000).toStringAsFixed(3);
    return s.replaceFirst(RegExp(r'0+$'), '');
  }

  static String _seatTag(Seat s) => switch (s) {
    Seat.aWhite => 'WA',
    Seat.aBlack => 'BA',
    Seat.bWhite => 'WB',
    Seat.bBlack => 'BB',
  };

  /// Human readable result comment, e.g. `WA checkmated`.
  static String resultComment(MatchResult r) {
    final loser = r.loser == null ? null : _seatTag(r.loser!);
    return switch (r.reason) {
      ResultReason.checkmate => '$loser checkmated',
      ResultReason.timeout => '$loser forfeits on time',
      ResultReason.resignation => '$loser resigns',
      ResultReason.abandonment => '$loser forfeits by disconnection',
      ResultReason.stalemate =>
        'Game drawn by stalemate on board ${r.board!.id.toUpperCase()}',
      ResultReason.repetition =>
        'Game drawn by repetition on board ${r.board!.id.toUpperCase()}',
      ResultReason.agreement => 'Game drawn by agreement',
    };
  }

  /// Sentence used on the results screen, e.g. `Team 2 wins by checkmate on board B`.
  static String headline(MatchResult r) {
    if (r.isDraw) {
      return switch (r.reason) {
        ResultReason.stalemate => 'Draw by stalemate',
        ResultReason.repetition => 'Draw by repetition',
        _ => 'Draw by agreement',
      };
    }
    final how = switch (r.reason) {
      ResultReason.checkmate => 'by checkmate',
      ResultReason.timeout => 'on time',
      ResultReason.resignation => 'by resignation',
      ResultReason.abandonment => 'by abandonment',
      _ => '',
    };
    final where = r.board == null
        ? ''
        : ' on board ${r.board!.id.toUpperCase()}';
    return 'Team ${r.winner!.id} wins $how$where';
  }
}

extension SeatColorLabel on PieceColor {
  String get label => this == PieceColor.white ? 'White' : 'Black';
}
