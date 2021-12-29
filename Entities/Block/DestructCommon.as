// fzzle @ 25/03/17

#include 'IslandsCommon.as';
#include 'AccurateSoundPlay.as';
#include 'ExplosionEffects.as';
#include 'WaterEffects.as';
#include 'Hitters.as';

namespace Destruct
{
	// Client- & server-side: Blow up an isle
	void self(CBlob@ this, float radius)
	{
		Vec2f position = this.getPosition();

		directionalSoundPlay('ShipExplosion', position);

		makeWaveRing(position, 4.5f, 7);

		makeLargeExplosionParticle(position);

		ShakeScreen(45, 40, position);

		if (!isServer()) return;

		uint8 team = this.getTeamNum();

		// Damage nearby entities
		CMap@ map = getMap();
		array<CBlob@> surrounding;

		map.getBlobsInRadius(position, radius, @surrounding);

		for (uint16 i = 0; i < surrounding.length; ++ i)
		{
			CBlob@ blob = surrounding[i];

			if (this is blob) continue;

			float initial = blob.getInitialHealth();
			float distance = this.getDistanceTo(blob);
			float damage = 1.5f * initial * (radius - distance) / radius;

			this.server_Hit(blob, position, Vec2f_zero, damage, Hitters::bomb, true);
		}

		// Kill island
		int color = this.getShape().getVars().customData;

		if (color == 0) return;

		Island@ isle = getIsland(color);

		if (isle is null) return;

		if (isle.blocks.length < 10) return;

		for (uint i = 0; i < isle.blocks.length; ++ i)
		{
			IslandBlock@ block = isle.blocks[i];

			CBlob@ blob = getBlobByNetworkID(block.blobID);

			if (blob is null) continue;

			if (blob is this) continue;

			if (team != blob.getTeamNum()) continue;

			blob.server_Die();
		}
	}
}
