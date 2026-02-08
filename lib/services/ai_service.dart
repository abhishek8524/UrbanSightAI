/// Stub AI moderation: heuristic rules only. No external API (e.g. Gemini).
/// Returns relevanceScore (0-1), suggestedCategory, reason for demo use.
class AiService {
  /// Analyzes report content and returns AI-style result.
  /// [imageUrl] is unused in stub (reserved for future image API).
  Future<Map<String, dynamic>> analyzeReport(
    String imageUrl,
    String description,
    String category,
  ) async {
    final text = description.trim().toLowerCase();
    final keywords = _categoryKeywords[category] ?? ['other'];
    final hasMatch = keywords.any((k) => text.contains(k));
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.length > 1).length;

    double relevanceScore;
    String suggestedCategory;
    String reason;

    if (hasMatch && wordCount >= 3) {
      relevanceScore = 0.85;
      suggestedCategory = category;
      reason = 'Description matches category and has sufficient detail.';
    } else if (hasMatch) {
      relevanceScore = 0.6;
      suggestedCategory = category;
      reason = 'Description matches category but is brief.';
    } else if (wordCount >= 5) {
      relevanceScore = 0.5;
      suggestedCategory = category;
      reason = 'Description is detailed; category match is uncertain (stub).';
    } else if (text.isEmpty) {
      relevanceScore = 0.2;
      suggestedCategory = category;
      reason = 'No description provided; cannot verify relevance (stub).';
    } else {
      relevanceScore = 0.4;
      suggestedCategory = category;
      reason = 'Limited keyword match; manual review recommended (stub).';
    }

    return {
      'relevanceScore': relevanceScore,
      'suggestedCategory': suggestedCategory,
      'reason': reason,
    };
  }

  static const Map<String, List<String>> _categoryKeywords = {
    'Pothole': ['pothole', 'hole', 'road', 'street', 'crack', 'damage', 'bump'],
    'Streetlight': ['light', 'lamp', 'streetlight', 'out', 'broken', 'dark'],
    'Graffiti': ['graffiti', 'spray', 'wall', 'vandalism', 'tag'],
    'Trash': ['trash', 'garbage', 'litter', 'debris', 'dump', 'waste'],
    'Sewage': ['sewage', 'sewer', 'overflow', 'smell', 'drain', 'water', 'leak'],
    'Other': ['issue', 'problem', 'report', 'other'],
  };
}
