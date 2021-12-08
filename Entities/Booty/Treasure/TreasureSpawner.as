#define SERVER_ONLY
#include "TileCommon.as"
//Spawn treasure randomly

const u16 FREQUENCY = 2*30;//30 = 1 second
const f32 CLEAR_RADIUS_FACTOR = 2.5f;
const f32 MAX_CLEAR_RADIUS = 700.0f;
const u32 PADDING = 80;//border spawn padding
const u32 MAX_PENALTY_TIME = 90 * 30 * 60;//time where the area of spawning is reduced to the centermap

void onTick(CRules@ this)
{
	if (getGameTime() % FREQUENCY > 0 || getRules().get_bool("whirlpool")) return;	
	
	CMap@ map = getMap();
	Vec2f mapDim = map.getMapDimensions();
	Vec2f center = Vec2f(mapDim.x/2, mapDim.y/2);
	f32 timePenalty = Maths::Max(0.0f, 1.0f - getGameTime()/MAX_PENALTY_TIME);
	//print( "<> " + getGameTime()/30/60 + " minutes penalty%: " + timePenalty );

	if (getTreasureCount() < 1)
	{
		for (u8 tries = 0; tries < 5; tries++)
		{
			Vec2f spot = Vec2f (center.x + 0.4f * (XORRandom(2) == 0 ? -1 : 1) * XORRandom(center.x - PADDING),
											center.y + 0.4f * (XORRandom(2) == 0 ? -1 : 1) * XORRandom(center.y - PADDING));
			if (zoneClear(map, spot, timePenalty < 0.2f))
			{
				createTreasure(spot);
				return;
			}
		}
		
		if (timePenalty > 0.4f)
		{
			for (u8 tries = 0; tries < 10; tries++)
			{
				Vec2f spot = Vec2f (center.x + timePenalty * (XORRandom(2) == 0 ? -1 : 1) * XORRandom(center.x - PADDING),
												center.y + timePenalty * (XORRandom(2) == 0 ? -1 : 1) * XORRandom(center.y - PADDING));
				if (zoneClear(map, spot))
				{
					createTreasure(spot);
					break;
				}
			}
		}
	}
}

void createTreasure(Vec2f pos)
{
    CBlob@ treasure = server_CreateBlobNoInit("treasure");
    if (treasure !is null)
	{
		treasure.server_setTeamNum(-1);
		treasure.setPosition(pos);
		treasure.Init();
	}
}

int getTreasureCount()
{
	CBlob@[] treasure;
	getBlobsByName("treasure", @treasure);

	return treasure.length;
}

bool zoneClear(CMap@ map, Vec2f spot, bool onlyTreasure = false)
{
	f32 clearRadius = Maths::Min(Maths::Sqrt(map.tilemapwidth * map.tilemapheight) * CLEAR_RADIUS_FACTOR, MAX_CLEAR_RADIUS);
	
	bool mothership = map.isBlobWithTagInRadius("mothership", spot, clearRadius * 0.5f);

	return isTouchingLand(spot) && (onlyTreasure || !mothership);
}
