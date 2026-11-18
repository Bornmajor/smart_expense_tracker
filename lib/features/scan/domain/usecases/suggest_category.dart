/// Suggests which category a scanned receipt belongs to, from words on it.
///
/// It only suggests: it returns null when nothing matches clearly, and the
/// user can always choose another category. It never invents a category the
/// user does not have: only ids in `availableIds` can be returned.
class SuggestCategory {
  const SuggestCategory();

  /// Words that point to each of the starting categories. A word matches whole
  /// ("bar" does not match "barcode"). Phrases are fine.
  static const _keywords = <String, List<String>>{
    'food': [
      'restaurant',
      'cafe',
      'café',
      'coffee',
      'bakery',
      'pizza',
      'pizzeria',
      'burger',
      'grill',
      'kitchen',
      'diner',
      'bistro',
      'eatery',
      'takeaway',
      'takeout',
      'supermarket',
      'grocery',
      'groceries',
      'butchery',
      'butcher',
      'juice',
      'lunch',
      'dinner',
      'breakfast',
      'meal',
      'food',
      'bar',
      'pub',
      'snack',
      'chicken',
      'deli',
    ],
    'transport': [
      'fuel',
      'petrol',
      'diesel',
      'gasoline',
      'unleaded',
      'petrol station',
      'filling station',
      'gas station',
      'shell',
      'bp',
      'chevron',
      'uber',
      'bolt',
      'lyft',
      'taxi',
      'cab',
      'parking',
      'toll',
      'bus',
      'matatu',
      'train',
      'railway',
      'airline',
      'airways',
      'flight',
      'car wash',
    ],
    'bills': [
      'electricity',
      'electric',
      'utility',
      'utilities',
      'water bill',
      'internet',
      'wifi',
      'airtime',
      'bundle',
      'bundles',
      'subscription',
      'insurance',
      'rent',
      'telecom',
      'bill',
      'netflix',
      'spotify',
    ],
    'shopping': [
      'clothing',
      'clothes',
      'fashion',
      'apparel',
      'boutique',
      'shoes',
      'footwear',
      'electronics',
      'mall',
      'hardware',
      'furniture',
      'books',
      'bookshop',
      'stationery',
      'gift',
      'gifts',
      'toys',
      'department store',
      'jewellery',
      'jewelry',
      'cosmetics',
      'beauty',
    ],
    'health': [
      'pharmacy',
      'pharmacist',
      'chemist',
      'hospital',
      'clinic',
      'dental',
      'dentist',
      'medical',
      'medicine',
      'doctor',
      'optician',
      'optical',
      'laboratory',
      'lab',
      'drug',
      'drugs',
      'health',
      'physio',
      'vitamin',
    ],
  };

  static final _patterns = {
    for (final entry in _keywords.entries)
      entry.key: [
        for (final word in entry.value)
          RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false),
      ],
  };

  /// A word in the vendor name says more than a word somewhere in the items.
  static const _vendorWeight = 3;

  /// The category id for the receipt, or null when it is unclear or a tie.
  String? call({
    required String? vendor,
    required List<String> lines,
    required Set<String> availableIds,
  }) {
    final body = lines.join('\n');
    final vendorText = vendor ?? '';

    final scores = <String, int>{};
    for (final entry in _patterns.entries) {
      if (!availableIds.contains(entry.key)) continue;

      var score = 0;
      for (final pattern in entry.value) {
        if (pattern.hasMatch(vendorText)) score += _vendorWeight;
        if (pattern.hasMatch(body)) score += 1;
      }
      if (score > 0) scores[entry.key] = score;
    }
    if (scores.isEmpty) return null;

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final tied = ranked.length > 1 && ranked[0].value == ranked[1].value;
    return tied ? null : ranked.first.key;
  }
}
