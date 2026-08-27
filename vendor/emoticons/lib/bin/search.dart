part of coUemoticons;

class _SortingEmoticon extends Emoticon implements Comparable {
	/// Emoticon we're sorting
	Emoticon emoticon;

	/// Lower number means more relevant
	int relevance;

	_SortingEmoticon(this.emoticon, this.relevance);

	@override
	String toString() => '[$relevance] $emoticon';

	@override
	int compareTo(dynamic other) {
		assert(other is _SortingEmoticon);
		return this.relevance.compareTo(other.relevance);
	}
}

Map<String, List<Emoticon>> _searchCache = {};

List<Emoticon> search(String needle) {
	// Clean up input
	needle = needle.trim().toLowerCase();

	// Check cache
	if (_searchCache[needle] != null) {
		return _searchCache[needle];
	}

	// Find how closely each emoticon matches
	List<_SortingEmoticon> pile = [];
	emoticons.forEach((Emoticon emoticon) {
		int relevance = min(levenshtein.distance(emoticon.name, needle),
			levenshtein.distance(emoticon.shortname, needle)) * 2;

		if (emoticon.keywords.join(',').contains(needle)) {
			relevance ~/= 2;
		}

		pile.add(new _SortingEmoticon(emoticon, relevance));
	});

	// Limit the number returned
	pile = pile.where((_SortingEmoticon emoticon) {
		return emoticon.relevance <= needle.length;
	}).toList();

	// Sort by relevance
	pile.sort();

	// Convert _SortingEmoticons back into emoticons
	List<Emoticon> pileEmoticons = [];
	pile.forEach((_SortingEmoticon emoticon) {
		pileEmoticons.add(emoticon.emoticon);
	});

	// Save to cache for later
	_searchCache[needle] = pileEmoticons;

	return pileEmoticons;
}
