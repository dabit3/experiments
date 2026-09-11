/// Text chat filtering used by the server before broadcasting a message and by
/// clients for the local preview.
///
/// The filter is family-friendly: blocked words are replaced with `#`
/// characters of the same length, digits sequences that look like phone
/// numbers are masked, and URLs are removed.
class ChatFilter {
  ChatFilter({Iterable<String>? blockedWords})
    : _blocked = {
        ...(blockedWords ?? defaultBlockedWords).map((w) => w.toLowerCase()),
      };

  final Set<String> _blocked;

  static const int maxLength = 140;

  /// Words replaced by hashes. Kept intentionally tame; the list is a test
  /// fixture, not a complete moderation system.
  static const List<String> defaultBlockedWords = [
    'stupid',
    'idiot',
    'dumb',
    'hate',
    'kill',
    'loser',
    'shut up',
    'noob',
    'ugly',
    'password',
  ];

  static final RegExp _url = RegExp(
    r'(https?://\S+|www\.\S+|\S+\.(com|net|org|io|gg)\b\S*)',
    caseSensitive: false,
  );
  static final RegExp _phone = RegExp(r'\d[\d\s\-().]{6,}\d');

  FilterResult filter(String input) {
    var text = input.trim();
    if (text.length > maxLength) text = text.substring(0, maxLength);
    var filtered = false;

    text = text.replaceAllMapped(_url, (m) {
      filtered = true;
      return '#' * m[0]!.length;
    });
    text = text.replaceAllMapped(_phone, (m) {
      filtered = true;
      return '#' * m[0]!.length;
    });
    for (final word in _blocked) {
      final pattern = RegExp(
        r'(?<![A-Za-z])' + RegExp.escape(word) + r'(?![A-Za-z])',
        caseSensitive: false,
      );
      text = text.replaceAllMapped(pattern, (m) {
        filtered = true;
        return '#' * m[0]!.length;
      });
    }
    return FilterResult(text, filtered);
  }
}

class FilterResult {
  const FilterResult(this.text, this.filtered);

  final String text;
  final bool filtered;
}
