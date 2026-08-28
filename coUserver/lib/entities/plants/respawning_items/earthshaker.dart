part of entity;

class EarthshakerRespawningItem extends RespawningItem {
	EarthshakerRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Earthshaker';
		itemType = 'earthshaker';
		respawnTime = new Duration(hours: 1);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/earthshaker-1-2-3-4.png',
				160, 54, 40, 54, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
