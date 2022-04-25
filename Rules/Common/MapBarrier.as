// force barrier around edge of map
#include "ShipsCommon.as";

CBlob@[] hitBlobs;
uint[] shipTimes;

void onInit(CRules@ this)
{
	this.addCommandID("ship bounce");
}

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
	
	const u8 borderBlobsLength = blobsAtBorder.length;
	if (borderBlobsLength > 0)
	{
		for (u8 i = 0; i < borderBlobsLength; i++)
		{
			CBlob@ b = blobsAtBorder[i];
			Ship@ ship = getShip(b.getShape().getVars().customData);
			if (ship !is null && ship.vel.LengthSquared() > 0)
			{
				Vec2f pos = b.getPosition();

				//determine bounce direction
				f32 bounceX = dim.x - 20 < pos.x ? -3.0f : pos.x - 20 < 0.0f ? 3.0f : ship.vel.x;
				f32 bounceY = dim.y - 20 < pos.y ? -3.0f : pos.y - 20 < 0.0f ? 3.0f : ship.vel.y;
				
				const u16 blocksLength = ship.blocks.length;
				if (blocksLength < 3)
				{
					//pinball machine!!!
					bool bounce = true;
					const u8 blobsLength = hitBlobs.length;
					for (u8 i = 0; i < blobsLength; i++)
					{
						//make sure ships don't bounce again too soon after first bounce
						if (hitBlobs[i] !is null && hitBlobs[i] is b)
							bounce = false;
					}
					
					if (bounce && ship.centerBlock !is null)
					{
						for (u16 i = 0; i < blocksLength; ++i)
						{
							CBlob@ b = getBlobByNetworkID(ship.blocks[i].blobID);
							if (b !is null)
							{
								hitBlobs.push_back(b);
								shipTimes.push_back(getGameTime());
							}
						}
						
						if (isServer())
						{
							f32 bounceFactor = dim.y - 20 < pos.y || pos.y - 20 < 0.0f ? -1 : 1; //account for all borders
							f32 bounceAngle = Vec2f(-ship.vel.y * bounceFactor, ship.vel.x * bounceFactor).Angle();
							while (bounceAngle < 0.0f)	 bounceAngle += 360.0f;
							while (bounceAngle > 360.0f) bounceAngle -= 360.0f;
							
							CBitStream bs;
							bs.write_netid(ship.centerBlock.getNetworkID());
							bs.write_f32(bounceAngle); //calculate perpendicular angle
							this.SendCommand(this.getCommandID("ship bounce"), bs); //synchronize
						}
					}
					ship.vel = Vec2f(bounceX / 1.5f, bounceY / 1.5f);
				}
				else
				{
					ship.vel = Vec2f(bounceX, bounceY);
					server_turnOffPropellers(ship);
				}
			}
		}
	}
	
	const u8 timeLength = shipTimes.length;
	for (u8 i = 0; i < timeLength; i++)
	{
		if (getGameTime() > shipTimes[i]+4) //timer to let ships bounce again
		{
			hitBlobs.erase(i);
			shipTimes.erase(i);
		}
	}
}

void server_turnOffPropellers(Ship@ ship)
{
	if (!isServer()) return;
	
	const u16 blocksLength = ship.blocks.length;
	for (u16 i = 0; i < blocksLength; ++i)
	{
		ShipBlock@ ship_block = ship.blocks[i];
		if (ship_block is null) continue;

		CBlob@ block = getBlobByNetworkID(ship_block.blobID);
		if (block is null) continue;
		
		//set all propellers off on the ship
		if (block.hasTag("engine"))
		{
			block.set_f32("power", 0);
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("ship bounce"))
	{
		CBlob@ centerblock = getBlobByNetworkID(params.read_netid());
		if (centerblock is null) return;
		
		Ship@ ship = getShip(centerblock.getShape().getVars().customData);
		if (ship is null) return;
		
		ship.angle = params.read_f32();
	}
}