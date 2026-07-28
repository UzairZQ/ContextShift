String mergeDictationText(String base, String transcript) {
  final left = base.trim();
  final right = transcript.trim();
  if (left.isEmpty) return right;
  if (right.isEmpty || left == right) return left;

  final leftWords = left.split(RegExp(r'\s+'));
  final rightWords = right.split(RegExp(r'\s+'));
  final maxOverlap = leftWords.length < rightWords.length
      ? leftWords.length
      : rightWords.length;

  for (var overlap = maxOverlap; overlap > 0; overlap--) {
    final leftStart = leftWords.length - overlap;
    var matches = true;
    for (var index = 0; index < overlap; index++) {
      if (leftWords[leftStart + index].toLowerCase() !=
          rightWords[index].toLowerCase()) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return [...leftWords, ...rightWords.skip(overlap)].join(' ');
    }
  }

  return '$left $right';
}

/// Keeps finished speech-recognition sessions separate from the live partial
/// result. Speech plugins reset their partial transcript after pauses and
/// restarts, so treating every callback as the complete prompt loses text.
class DictationTranscript {
  DictationTranscript([String initialText = ''])
    : _committed = initialText.trim();

  String _committed;
  String _session = '';

  String get text => mergeDictationText(_committed, _session);
  bool get isEmpty => text.isEmpty;

  void reset(String text) {
    _committed = text.trim();
    _session = '';
  }

  void update(String transcript, {required bool isFinal}) {
    final words = transcript.trim();
    if (words.isEmpty && !isFinal) return;
    _session = words;
    if (isFinal) commitSession();
  }

  void commitSession() {
    _committed = mergeDictationText(_committed, _session);
    _session = '';
  }
}
