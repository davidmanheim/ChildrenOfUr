part of entity;

class ButterflyMilkRespawningItem extends RespawningItem {
	ButterflyMilkRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Butterfly Milk';
		itemType = 'butterfly_milk';
		respawnTime = new Duration(minutes: 1);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/butterfly_milk-1-2-3-4.png',
				148, 45, 37, 45, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
