part of entity;

class Auctioneer extends NPC {
	Auctioneer(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		actionTime = 0;
		actions.add(
			new Action.withName('Talk To')
		);

		type = "Auctioneer";
		speed = 0;

		states = {
			"idle":new Spritesheet("idle", 'files/sprites/generated/converted/auctioneer-idle.png', 19075, 193, 175, 193, 109, true, loopDelay:5000),
			"talk":new Spritesheet("talk", 'files/sprites/generated/converted/auctioneer-talk.png', 12600, 193, 175, 193, 72, false),
			"walk":new Spritesheet("walk", 'files/sprites/generated/converted/auctioneer-walk.png', 2800, 193, 175, 193, 16, true)
		};
		setState('idle');
	}

	void update({bool simulateTick: false}) {

	}

	void talkTo({WebSocket userSocket, String email}) {
		Map map = {};
		map['vendorName'] = type;
		map['id'] = id;
		userSocket.add(jsonEncode(map));
	}
}