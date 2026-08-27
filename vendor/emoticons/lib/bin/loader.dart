part of coUemoticons;

Future _loadEmojione(Asset json) async {
	await json.load();

	Map<String, dynamic> emoticons = json.get() as Map;
	emoticons.forEach((String id, dynamic emoticon) {
		if (emoticon['hidden'] as bool == true) {
			return;
		}

		if ((emoticon['name'] as String).contains('modifier')) {
			return;
		}

		try {
			_emoticons.addAll({id: new Emoticon(
				id: id,
				unicode: emoticon['unicode'] as String,
				name: emoticon['name'] as String,
				shortname: emoticon['shortname'] as String,
				category: emoticon['category'] as String,
				order: int.parse(emoticon['emoji_order'].toString()),
				aliases: (emoticon['aliases_ascii'] as List).cast<String>(),
				keywords: (emoticon['keywords'] as List).cast<String>()
			)});
		} catch (e) {
			print('coUemoticons: Could not load emoticon $id: $e');
		}
	});
}

Future _loadCou(Asset json) async {
	await json.load();

	Map<String, dynamic> emoticons = json.get() as Map;
	List<String> names = (emoticons['names'] as List).cast<String>();
	names.forEach((String id) {
		try {
			_emoticons.addAll({id: new Emoticon(
				id: id,
				name: id,
				shortname: ':$id:',
				category: 'CoU'
			)});
		} catch (e) {
			print('coUemoticons: Could not load emoticon $id: $e');
		}
	});
}