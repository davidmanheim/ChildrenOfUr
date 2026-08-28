part of entity;

class FruityJuiceRespawningItem extends RespawningItem {
	FruityJuiceRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Fruity Juice';
		itemType = 'fruity_juice';
		respawnTime = new Duration(minutes: 3);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/fruity_juice-1-2-3-4.png',
				248, 93, 62, 93, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
