part of entity;

class Quoin
{
	// The original remotely-hosted sprite is no longer available.  This is a
	// local generated fallback used by the synthetic local-world seed, and
	// remains the fallback for any type below without real converted art.
	static const String fallbackUrl = "files/sprites/generated/local-quoin.svg";

	// Real art converted from tmp/glitch-items/misc/quoin/quoin.swf (see
	// content/source-manifest.json). Keyed by the lowercase type string as
	// constructed below (street.dart already does `type.toLowerCase()`
	// before calling this constructor, and setCollected() below already
	// compares against the lowercase "quarazy"), so no further case
	// conversion happens here. "currant" intentionally does not match the
	// source symbol name "quoin_currants_thumb" -- a pre-existing
	// singular/plural naming mismatch between this game's type string and
	// the original asset, not something to change.
	static const Map<String, String> typeUrls = {
		"img": "files/sprites/generated/converted/quoin-img.png",
		"mood": "files/sprites/generated/converted/quoin-mood.png",
		"energy": "files/sprites/generated/converted/quoin-energy.png",
		"currant": "files/sprites/generated/converted/quoin-currant.png",
		"mystery": "files/sprites/generated/converted/quoin-mystery.png",
		"favor": "files/sprites/generated/converted/quoin-favor.png",
		"time": "files/sprites/generated/converted/quoin-time.png",
		"quarazy": "files/sprites/generated/converted/quoin-quarazy.png",
	};

	String id, type;
	int x,y;
	DateTime respawn;
	bool collected = false;

	String get url => typeUrls[type] ?? fallbackUrl;

	Quoin(this.id,this.x,this.y,this.type);

	/**
	 * Will check for quoin collection/spawn and send updates to clients if needed
	 */
	update({bool simulateTick: false}) {
		if(respawn != null && new DateTime.now().compareTo(respawn) >= 0) {
			collected = false;
		}
	}

	setCollected(String username) {
		User.getEmailFromUsername(username).then((String email) {
			if (email != null) {
				StatManager.add(email, Stat.quoins_collected);
			}
		});

		if (type == "quarazy") {
			/*  Quarazy quoin should never be set to 'collected'
				to enable all users to collect it
				it will not be shown to a player again once collected,
				(handled in the client)                                 */
			return;
		}

		collected = true;
		int duration = (type == "mystery" ? 90 : 30);
		respawn = new DateTime.now().add(new Duration(seconds: duration));
	}

	Map<String, dynamic> getMap() => {
		"id": id,
		"url": url,
		"type": type,
		"remove": collected.toString(),
		"x": x,
		"y": y
	};
}
