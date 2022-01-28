shared class Island
{
	u32 id;                   //island's specific identification 
	IslandBlock[] blocks;     //all blocks on the same island
	Vec2f pos, vel;           //position, velocity
	f32 angle, angle_vel;     //angle of island, angular velocity
	Vec2f old_pos, old_vel;   //comparing new to old position, velocity
	f32 old_angle;            //comparing new to old angle
	f32 mass, carryMass;      //weight of the entire island, weight carried by a player
	CBlob@ centerBlock;       //the block in the center of the entire island
	bool initialized;	      //onInit for islands
	uint soundsPlayed;        //used in limiting sounds in propellers
	string owner;             //username of the player who has 'claimed' the island
	bool isMothership;        //is the ship connected to a core?
	bool isStation;           //is the ship connected to a station?
	bool isMiniStation;       //is the ship connected to a mini station?
	bool isSecondaryCore;     //is the ship connected to an auxillary core?
	bool beached;             //is the ship touching land?
	bool slowed;              //is the ship touching a shoal?
	
	Vec2f net_pos, net_vel;        //network
	f32 net_angle, net_angle_vel;  //network

	Island()
	{
		angle = angle_vel = old_angle = mass = carryMass = 0.0f;
		initialized = false;
		isMothership = false;
		isStation = false;
		isMiniStation = false;
		isSecondaryCore = false;
		beached = false;
		slowed = false;
		@centerBlock = null;
		soundsPlayed = 0;
		owner = "";
	}
};

shared class IslandBlock
{
	u16 blobID;
	Vec2f offset;
	f32 angle_offset;
};

Island@ getIsland(const int colorIndex)
{
	Island[]@ islands;
	if (getRules().get("islands", @islands))
	{
		if (colorIndex > 0 && colorIndex <= islands.length)
		{
			return islands[colorIndex-1];
		}
	}
	return null;
}

Island@ getIsland(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(this.getPosition(), 1.0f, @blobsInRadius)) 
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
            const int color = b.getShape().getVars().customData;
            if (color > 0)
            {
            	return getIsland(color);
            }
		}
	}
    return null;
}

CBlob@ getIslandBlob(CBlob@ this) //Gets the block blob wherever 'this' is positioned
{
	CBlob@ b = null;
	f32 mDist = 9999;
	CBlob@[] blobsInRadius;	   
	if (getMap().getBlobsInRadius(this.getPosition(), 1.0f, @blobsInRadius))//custom getIslandBlob();
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			if (blobsInRadius[i].getShape().getVars().customData > 0)
			{
				f32 dist = this.getDistanceTo(blobsInRadius[i]);
				if (dist < mDist)
				{
					@b = blobsInRadius[i];
					mDist = dist;
				}
			}
		}
	}

	return b;
}

Vec2f SnapToGrid(Vec2f pos) //determines the grid of blocks
{
    pos.x = Maths::Round(pos.x / 8.0f);
    pos.y = Maths::Round(pos.y / 8.0f);
    pos.x *= 8;
    pos.y *= 8;
    return pos;
}

void SetNextId(CRules@ this, Island@ island)
{
	this.add_s32("islands id", 1);
	island.id = this.get_s32("islands id");
}

CBlob@ getMothership(const u8 team) //Gets the mothership core block on determined team 
{
    CBlob@[] ships;
    getBlobsByTag("mothership", @ships);
    for (uint i=0; i < ships.length; i++)
    {
        CBlob@ ship = ships[i];  
        if (ship.getTeamNum() == team)
            return ship;
    }
    return null;
}

bool isMothership(CBlob@ this) //Determine if an island has a mothership core attached to it
{
	const int color = this.getShape().getVars().customData;
	if (color == 0) return false;
	
	Island@ island = getIsland(color);
	if (island !is null)
		return island.isMothership;
	else
		return false;
}

string getCaptainName(u8 team) //Gets the name of the mothership's captain
{
	CBlob@[] cores;
	getBlobsByTag("mothership", @cores);
	for (u8 i = 0; i < cores.length; i++)
	{
		if (cores[i].getTeamNum() != team) continue;
			
		Island@ isle = getIsland( cores[i].getShape().getVars().customData);
		if (isle !is null && isle.owner != "")
			return isle.owner;
	}
	return "";
}

bool blocksOverlappingIsland(CBlob@[]@ blocks)
{
    for (uint i = 0; i < blocks.length; ++i)
    {
        CBlob @block = blocks[i];
        if (blockOverlappingIsland(block))
            return true;
    }
    return false; 
}

bool blockOverlappingIsland(CBlob@ blob)
{
    CBlob@[] overlapping;
    if (getMap().getBlobsInRadius(blob.getPosition(), 8.0f, @overlapping))
    {
        for (uint i = 0; i < overlapping.length; i++)
        {
            CBlob@ b = overlapping[i];
            int color = b.getShape().getVars().customData;
            if (color > 0)
            {
                if ((b.getPosition() - blob.getPosition()).getLength() < blob.getRadius()*0.4f)
                    return true;
            }
        }
    }
    return false;
}

bool coreLinkedDirectional(CBlob@ this, u16 token, Vec2f corePos )//checks if the block leads up to a core. doesn't follow up couplings/repulsors. accounts for core position
{
	if (this.hasTag("mothership"))
		return true;

	this.set_u16( "checkToken", token );
	bool childsLinked = false;
	Vec2f thisPos = this.getPosition();
	
	CBlob@[] overlapping;
	if (this.getOverlapping(@overlapping))
	{
		f32 minDist = 99999.0f;
		f32 minDist2;
		CBlob@[] optimal;
		for (int i = 0; i < overlapping.length; i++)
		{
			CBlob@ b = overlapping[i];
			Vec2f bPos = b.getPosition();
			
			f32 coreDist = (bPos - corePos).LengthSquared();
			if (b.get_u16("checkToken") != token && (bPos - thisPos).LengthSquared() < 78 && !b.hasTag("removable") && b.hasTag("block"))//maybe should do a color > 0 check
			{
				if (coreDist <= minDist)
				{
					optimal.insertAt( 0, b );
					minDist2 = minDist;	
					minDist = coreDist;
				}
				else if (coreDist <= minDist2)
				{
					optimal.insertAt( 0, b );
					minDist2 = coreDist;
				}
				else
					optimal.push_back(b);
			}
		}
		
		for (int i = 0; i < optimal.length; i++)
		{
			//print( ( optimal[i].hasTag( "mothership" ) ? "[>] " : "[o] " ) + optimal[i].getNetworkID() );
			if (coreLinkedDirectional(optimal[i], token, corePos))
			{
				childsLinked = true;
				break;
			}
		}
	}
		
	return childsLinked;
}
