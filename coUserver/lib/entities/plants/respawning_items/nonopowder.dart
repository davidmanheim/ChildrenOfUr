part of entity;

class NoNoPowderRespawningItem extends RespawningItem {
	NoNoPowderRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'No-No Powder';
		itemType = 'no_no_powder';
		respawnTime = new Duration(seconds: 30);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/nonopowder-1-2-3-4.png',
				340, 55, 85, 55, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
