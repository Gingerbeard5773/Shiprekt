// force barrier around edge of map
#include "IslandsCommon.as"
#include "BlockCommon.as"

void onTick(CRules@ this)
{
	CMap@ map = getMap();
	if (map is null) return;

	Vec2f dim = map.getMapDimensions();

	CBlob@[] blobsAtBorder;

	//create borders
	map.getBlobsInBox(dim, Vec2f(0.0f, dim.y), @blobsAtBorder);
	map.getBlobsInBox(dim, Vec2f(dim.x, 0.0f), @blobsAtBorder);
	map.getBlobsInBox(Vec2f(dim.x, 0.0f), Vec2f(), @blobsAtBorder);
	map.getBlobsInBox(Vec2f(0.0f, dim.y), Vec2f(), @blobsAtBorder);
	
	if (blobsAtBorder.length > 0)
	{
		for (uint i = 0; i < blobsAtBorder.length; i++)
		{
			CBlob @b = blobsAtBorder[i];
			Island@ island = getIsland(b.getShape().getVars().customData);
			if (island !is null && (isServer() || island.vel.LengthSquared() > 0))
			{
				Vec2f pos = b.getPosition();

				//determine bounce direction
				f32 bounceX = dim.x < pos.x ? -3.0f : pos.x < 0.0f ? 3.0f : island.vel.x;
				f32 bounceY = dim.y < pos.y ? -3.0f : pos.y < 0.0f ? 3.0f : island.vel.y;
				island.vel = Vec2f(bounceX, bounceY);

				server_turnOffPropellers(island);
			}
		}
	}
}

void server_turnOffPropellers(Island@ island)
{
	if (isServer()) return;
	
	for (uint i = 0; i < island.blocks.length; ++i)
	{
		IslandBlock@ isle_block = island.blocks[i];
		if (isle_block is null) continue;

		CBlob@ block = getBlobByNetworkID(isle_block.blobID);
		if (block is null) continue;
		
		//set all propellers off on the island
		if (block.hasTag("propeller"))
		{
			block.set_f32("power", 0);
		}
	}
}
