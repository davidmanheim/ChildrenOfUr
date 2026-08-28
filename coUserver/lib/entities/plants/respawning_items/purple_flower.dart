part of entity;

class PurpleFlowerRespawningItem extends RespawningItem {
	PurpleFlowerRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Purple Flower';
		itemType = 'purple_flower';
		respawnTime = new Duration(minutes: 3);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/purple_flower-1-2-3-4.png',
				272, 53, 68, 53, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
