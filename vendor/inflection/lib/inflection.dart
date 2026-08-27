library inflection;

String pluralize(String word) {
  if (word == null || word.isEmpty) return word;

  final lower = word.toLowerCase();
  const irregular = <String, String>{
    'person': 'people',
    'child': 'children',
    'mouse': 'mice',
    'goose': 'geese',
    'tooth': 'teeth',
  };
  if (irregular.containsKey(lower)) return _preserveCase(word, irregular[lower]);
  if (lower.endsWith('s') || lower.endsWith('x') || lower.endsWith('z') ||
      lower.endsWith('ch') || lower.endsWith('sh')) return word + 'es';
  if (lower.endsWith('y') && word.length > 1 &&
      !'aeiou'.contains(lower[lower.length - 2])) {
    return word.substring(0, word.length - 1) + 'ies';
  }
  return word + 's';
}

String _preserveCase(String original, String replacement) {
  if (original == original.toUpperCase()) return replacement.toUpperCase();
  if (original[0] == original[0].toUpperCase()) {
    return replacement[0].toUpperCase() + replacement.substring(1);
  }
  return replacement;
}
