part of entity;

class CoffeeRespawningItem extends RespawningItem {
	CoffeeRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Coffee';
		itemType = 'coffee';
		respawnTime = new Duration(seconds: 30);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/coffee-1-2-3-4.png',
				196, 33, 49, 33, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
