part of coUemoticons;

final RegExp _CHAT_REGEX = new RegExp("::(.+?)::");

String _makeImgTag(Emoticon emoticon) {
	return '<img class="emoticon" title="${emoticon.name}" src="${emoticon.imageUrl}">';
}

String parseIn(String message) {
	String parsed = '';

	// Parse by id

	message.splitMapJoin(_CHAT_REGEX, onMatch: (Match match) {
		if (_emoticons.keys.contains(match[1])) {
			Emoticon emoticon = _emoticons[match[1]];
			parsed += _makeImgTag(emoticon);
		} else {
			parsed += match[0];
		}
	}, onNonMatch: (String s) => parsed += s);

	// Automatically convert ASCII to emoji

	parsed = parsed
		.replaceAll('<span class="message">', '<span class="message"> ')
		.replaceAll('</span>', ' </span>');

	for (Emoticon emoticon in emoticons) {
		for (String alias in emoticon.aliases) {
			parsed = parsed.replaceAll(' $alias ', _makeImgTag(emoticon));
		}
	}

	return parsed;
}