part of entity;

class CinnamonRespawningItem extends RespawningItem {
	CinnamonRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Cinnamon';
		itemType = 'cinnamon';
		respawnTime = new Duration(minutes: 2);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/cinnamon-1-2-3-4.png',
				208, 18, 52, 18, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
