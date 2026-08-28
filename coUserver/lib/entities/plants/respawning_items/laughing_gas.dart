part of entity;

class LaughingGasRespawningItem extends RespawningItem {
	LaughingGasRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Laughing Gas';
		itemType = 'gas_laughing';
		respawnTime = new Duration(minutes: 3);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/laughing_gas-1-2-3-4.png',
				208, 43, 52, 43, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
