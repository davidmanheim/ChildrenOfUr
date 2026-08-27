library levenshtein;

import 'dart:math';

/*
 * From https://pub.dartlang.org/packages/edit_distance,
 * which is provided with the BSD 3-clause license allowing reuse here,
 * but not imported because that package has additional features with unreasonable dependencies for this project.
 */
int distance(String s1, String s2) {
	if (s1 == s2) {
		return 0;
	}

	if (s1.length == 0) {
		return s2.length;
	}

	if (s2.length == 0) {
		return s1.length;
	}

	List<int> v0 = new List<int>(s2.length + 1);
	List<int> v1 = new List<int>(s2.length + 1);
	List<int> vtemp;

	for (var i = 0; i < v0.length; i++) {
		v0[i] = i;
	}

	for (var i = 0; i < s1.length; i++) {
		v1[0] = i + 1;

		for (var j = 0; j < s2.length; j++) {
			int cost = 1;
			if (s1.codeUnitAt(i) == s2.codeUnitAt(j)) {
				cost = 0;
			}
			v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
		}

		vtemp = v0;
		v0 = v1;
		v1 = vtemp;
	}

	return v0[s2.length];
}
