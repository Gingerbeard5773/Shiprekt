// force barrier around edge of map
#include "IslandsCommon.as";

CBlob@[] hitBlobs;
uint[] islandTimes;

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
				f32 bounceX = dim.x - 20 < pos.x ? -3.0f : pos.x - 20 < 0.0f ? 3.0f : island.vel.x;
				f32 bounceY = dim.y - 20 < pos.y ? -3.0f : pos.y - 20 < 0.0f ? 3.0f : island.vel.y;
				
				if (island.blocks.length < 3)
				{
					//pinball machine!!!
					bool bounce = true;
					for (uint i = 0; i < hitBlobs.length; i++)
					{
						//make sure islands don't bounce again too soon after first bounce
						if (hitBlobs[i] is b)
							bounce = false;
					}
					
					if (bounce)
					{
						for (uint i = 0; i < island.blocks.length; ++i)
						{
							CBlob@ b = getBlobByNetworkID(island.blocks[i].blobID);
							if (b !is null)
							{
								hitBlobs.push_back(b);
								islandTimes.push_back(getGameTime());
							}
						}
						
						f32 bounceFactor = dim.y - 20 < pos.y || pos.y - 20 < 0.0f ? -1 : 1; //account for all borders
						island.angle = Vec2f(-island.vel.y * bounceFactor, island.vel.x * bounceFactor).Angle(); //calculate perpendicular angle
					}
					island.vel = Vec2f(bounceX / 1.5f, bounceY / 1.5f);
				}
				else
				{
					island.vel = Vec2f(bounceX, bounceY);
					server_turnOffPropellers(island);
				}
			}
		}
	}
	
	for (uint i = 0; i < islandTimes.length; i++)
	{
		if (getGameTime() > islandTimes[i]+4) //timer to let islands bounce again
		{
			hitBlobs.erase(i);
			islandTimes.erase(i);
		}
	}
}

void server_turnOffPropellers(Island@ island)
{
	if (!isServer()) return;
	
	for (uint i = 0; i < island.blocks.length; ++i)
	{
		IslandBlock@ isle_block = island.blocks[i];
		if (isle_block is null) continue;

		CBlob@ block = getBlobByNetworkID(isle_block.blobID);
		if (block is null) continue;
		
		//set all propellers off on the island
		if (block.hasTag("engine"))
		{
			block.set_f32("power", 0);
		}
	}
}
