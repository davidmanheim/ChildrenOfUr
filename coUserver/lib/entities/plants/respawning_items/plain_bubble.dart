part of entity;

class PlainBubbleRespawningItem extends RespawningItem {
	PlainBubbleRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Plain Bubble';
		itemType = 'plain_bubble';
		respawnTime = new Duration(seconds: 30);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/plain_bubble-1-2-3-4.png',
				152, 38, 38, 38, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
