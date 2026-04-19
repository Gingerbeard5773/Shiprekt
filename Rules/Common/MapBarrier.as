//bouncy map borders
#define SERVER_ONLY
#include "ShipsCommon.as";

const f32 thickness = 10.0f;
const f32 barrier_force = 3.0f;

void onTick(CRules@ this)
{
	CMap@ map = getMap();
	if (map is null) return;

	ShipDictionary@ ShipSet = getShipSet(this);

	const Vec2f dim = map.getMapDimensions();

	//simulate borders on each side of the map
	CBlob@[] blobsAtBorder;
	
	Vec2f[] borders =
	{
		Vec2f(0, 0), Vec2f(thickness, dim.y), // LEFT
		Vec2f(dim.x - thickness, 0), Vec2f(dim.x, dim.y), // RIGHT
		Vec2f(0, 0), Vec2f(dim.x, thickness), // TOP
		Vec2f(0, dim.y - thickness), Vec2f(dim.x, dim.y) // BOTTOM
	};

	for (u8 i = 0; i < 8; i += 2)
	{
		blobsAtBorder.clear();
		map.getBlobsInBox(borders[i], borders[i+1], @blobsAtBorder);

		const int borderBlobsLength = blobsAtBorder.length;
		for (int i = 0; i < borderBlobsLength; i++)
		{
			CBlob@ b = blobsAtBorder[i];
			const int bCol = b.getShape().getVars().customData;
			if (bCol <= 0) continue;

			Ship@ ship = ShipSet.getShip(bCol);
			if (ship is null) continue;

			const Vec2f pos = b.getPosition();

			//determine bounce direction
			const f32 bounceX = dim.x - 20 < pos.x ? -barrier_force : pos.x - 20 < 0.0f ? barrier_force : ship.vel.x;
			const f32 bounceY = dim.y - 20 < pos.y ? -barrier_force : pos.y - 20 < 0.0f ? barrier_force : ship.vel.y;

			ship.vel = Vec2f(bounceX, bounceY);
			server_turnOffPropellers(ship);
		}
	}
}

void server_turnOffPropellers(Ship@ ship)
{
	const u16 blocksLength = ship.blocks.length;
	for (u16 i = 0; i < blocksLength; ++i)
	{
		CBlob@ block = getBlobByNetworkID(ship.blocks[i].blobID);
		if (block !is null && block.hasTag("engine"))
			block.set_f32("power", 0);
	}
}
