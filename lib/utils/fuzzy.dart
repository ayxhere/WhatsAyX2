/// WZH-style fuzzy search: Levenshtein edit-distance ranking
/// (NOT substring `contains`). Pure Dart — no Flutter imports.
///
/// A substring match scores highest; otherwise the score comes from
/// the edit distance relative to the candidate length, so typos and
/// partial words still match and the best matches rank first.
int editDist(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (j) => j);
  var cur = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var best = prev[j] + 1;
      final ins = cur[j - 1] + 1;
      if (ins < best) best = ins;
      final sub = prev[j - 1] + cost;
      if (sub < best) best = sub;
      cur[j] = best;
    }
    final tmp = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[b.length];
}

/// Score of [query] against one candidate string, 0.0–1.0.
/// Returns 0 when there is no plausible match (caller filters those out).
double fuzzyScore(String query, String candidate) {
  final q = query.trim().toLowerCase();
  final c = candidate.trim().toLowerCase();
  if (q.isEmpty || c.isEmpty) return 0;
  if (c == q) return 1;
  // Strong bonus for a substring hit; earlier + longer coverage wins.
  final at = c.indexOf(q);
  if (at >= 0) {
    return 0.85 + 0.15 * (q.length / c.length) - at * 0.005;
  }
  // Otherwise score by edit distance relative to the longer string.
  // Only the best-matching word of a multi-word candidate counts,
  // so "Raju Kumar" still matches a typo'd "raju".
  var best = 0.0;
  for (final word in c.split(' ')) {
    if (word.isEmpty) continue;
    final longer = q.length > word.length ? q.length : word.length;
    final d = editDist(q, word);
    // Allow roughly one typo per 3 characters; beyond that, no match.
    if (d > (longer / 3).ceil() + 1) continue;
    final s = 0.7 * (1 - d / longer);
    if (s > best) best = s;
  }
  return best;
}

/// Rank [candidates] by how well each matches [query] (best first).
/// [textOf] extracts the searchable text for a candidate.
/// Returns only candidates with a positive score.
List<T> fuzzyFilter<T>(String query, List<T> candidates, String Function(T) textOf) {
  if (query.trim().isEmpty) return List<T>.from(candidates);
  final scored = <({T item, double score})>[];
  for (final item in candidates) {
    final s = fuzzyScore(query, textOf(item));
    if (s > 0) scored.add((item: item, score: s));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.map((e) => e.item).toList();
}
