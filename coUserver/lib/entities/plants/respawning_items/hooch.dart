part of entity;

class HoochRespawningItem extends RespawningItem {
	HoochRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Hooch';
		itemType = 'hooch';
		respawnTime = new Duration(minutes: 7);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/hooch-1-2-3-4.png',
				188, 51, 47, 51, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
