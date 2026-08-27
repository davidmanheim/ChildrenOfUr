part of entity;

class Quoin
{
	// The original remotely-hosted sprite is no longer available.  This is a
	// local generated fallback used by the synthetic local-world seed.
	String url = "files/sprites/generated/local-quoin.svg";
	String id, type;
	int x,y;
	DateTime respawn;
	bool collected = false;

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
