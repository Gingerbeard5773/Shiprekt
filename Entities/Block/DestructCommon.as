// fzzle @ 25/03/17

#include "ShipsCommon.as";
#include "AccurateSoundPlay.as";
#include "ExplosionEffects.as";
#include "WaterEffects.as";
#include "Hitters.as";

namespace Destruct
{
	// Client- & server-side: Blow up a ship
	void self(CBlob@ this, float radius)
	{
		Vec2f position = this.getPosition();

		if (isClient())
		{
			//effects
			directionalSoundPlay("ShipExplosion", position);
			makeWaveRing(position, 4.5f, 7);
			makeLargeExplosionParticle(position);
			ShakeScreen(45, 40, position);
		}

		if (!isServer()) return;

		// Damage nearby entities
		CMap@ map = getMap();
		CBlob@[] surrounding;

		map.getBlobsInRadius(position, radius, @surrounding);
		const u16 surroundingLength = surrounding.length;
		for (u16 i = 0; i < surroundingLength; ++ i)
		{
			CBlob@ blob = surrounding[i];
			if (this is blob) continue;

			float initial = blob.getInitialHealth();
			float distance = this.getDistanceTo(blob);
			float damage = 1.5f * initial * (radius - distance) / radius;

			this.server_Hit(blob, position, Vec2f_zero, Maths::Max(0.1f, damage), Hitters::bomb, true);
		}

		// Kill ship
		int color = this.getShape().getVars().customData;
		if (color <= 0) return;

		Ship@ ship = getShipSet().getShip(color);
		if (ship is null) return;
		
		const u16 blocksLength = ship.blocks.length;
		if (blocksLength < 10) return;
		
		if (this.hasTag("secondaryCore") && ship.isMothership) return; //dont kill mothership if this is a secondaryCore

		for (u16 i = 0; i < blocksLength; ++ i)
		{
			ShipBlock@ block = ship.blocks[i];
			CBlob@ blob = getBlobByNetworkID(block.blobID);

			if (blob is null || blob is this) continue;

			if (this.getTeamNum() != blob.getTeamNum()) continue;

			blob.server_Die();
		}
	}
}
