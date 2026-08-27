part of coUemoticons;

class Emoticon {
	/// Unique and sanitized
	String id;

	/// Unicode encoding, like `1f4af`
	String unicode;

	/// Full name (`hundred points symbol`)
	String name;

	/// Short name for auto-replacing (`:100:`)
	String shortname;

	/// Category (`symbols`)
	String category;

	/// Sort order
	int order = 0;

	/// Convert from text
	List<String> aliases = [];

	/// Makes searching easier
	List<String> keywords = [];

	/// Create an emoticon from stored values
	Emoticon({
		this.id,
		this.unicode,
		this.name,
		this.shortname,
		this.category,
		this.order: 0,
		this.aliases: const [],
		this.keywords: const []
	});

	/// File URL relative to package root
	String get imageUrl {
		if (category == 'CoU') {
			return '$IMG/$name.svg';
		} else {
			return '$IMG/emojione/$unicode.svg';
		}
	}

	@override
	String toString() => name;
}