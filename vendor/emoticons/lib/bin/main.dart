library coUemoticons;

import 'package:coUemoticons/levenshtein.dart' as levenshtein;

import 'dart:async';
import 'dart:math';

import 'package:libld/libld.dart';

part 'chat.dart';
part 'emoticon.dart';
part 'loader.dart';
part 'search.dart';

final String PATH = 'packages/coUemoticons';
final String IMG = '$PATH/img';

Map<String, Emoticon> _emoticons = {};
List<Emoticon> get emoticons => _emoticons.values.toList();

Completer _load = new Completer();
Completer get load => _load;

Future main() async {
	await Future.wait([
		_loadCou(new Asset('$PATH/couemoji.json')),
//		_loadEmojione(new Asset('$PATH/emojione.json')),
	]);

	load.complete();
}