part of entity;

/// Offline visual stand-ins used only by the synthetic local-world seed.
/// They are intentionally non-harvestable: they make the reconstructed map
/// readable without claiming to reproduce the missing original placements.
class DemoTree extends Plant {
	DemoTree(String id, num x, num y, num z, num rotation, bool hFlip, String streetName)
		: super(id, x, y, z, rotation, hFlip, streetName) {
		type = 'Demo Tree';
		state = maxState = 0;
		states = {
			'idle': new Spritesheet('idle', 'files/sprites/generated/demo-tree.svg',
				160, 220, 160, 220, 1, true)
		};
		setState('idle');
	}
}

class DemoWheat extends Plant {
	DemoWheat(String id, num x, num y, num z, num rotation, bool hFlip, String streetName)
		: super(id, x, y, z, rotation, hFlip, streetName) {
		type = 'Demo Wheat';
		state = maxState = 0;
		states = {
			'idle': new Spritesheet('idle', 'files/sprites/generated/demo-wheat.svg',
				96, 120, 96, 120, 1, true)
		};
		setState('idle');
	}
}
