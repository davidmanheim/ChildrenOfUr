part of entity;

/// Offline visual stand-in used only by the synthetic local-world seed.
/// It deliberately has no gameplay actions or movement; the original animal
/// placements and sprite sheets have not been recovered.
class DemoChicken extends NPC {
	DemoChicken(String id, num x, num y, num z, num rotation, bool hFlip, String streetName)
		: super(id, x, y, z, rotation, hFlip, streetName) {
		type = 'Demo Chicken';
		dontFlip = true;
		states = {
			'idle': new Spritesheet('idle', 'files/sprites/generated/demo-chicken.svg',
				96, 80, 96, 80, 1, true)
		};
		setState('idle');
	}
}
