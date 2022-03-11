shared class Ship
{
	u32 id;                   //ship's specific identification 
	ShipBlock[] blocks;       //all blocks on a ship
	Vec2f pos, vel;           //position, velocity
	f32 angle, angle_vel;     //angle of ship, angular velocity
	Vec2f old_pos, old_vel;   //comparing new to old position, velocity
	f32 old_angle;            //comparing new to old angle
	f32 mass, carryMass;      //weight of the entire ship, weight carried by a player
	CBlob@ centerBlock;       //the block in the center of the entire ship
	bool initialized;	      //onInit for ships
	uint soundsPlayed;        //used in limiting sounds in propellers
	string owner;             //username of the player who owns the ship
	bool isMothership;        //is the ship connected to a core?
	bool isStation;           //is the ship connected to a station?
	bool isMiniStation;       //is the ship connected to a ministation?
	bool isSecondaryCore;     //is the ship connected to an auxillary core?
	
	Vec2f net_pos, net_vel;        //network
	f32 net_angle, net_angle_vel;  //network

	Ship()
	{
		angle = angle_vel = old_angle = mass = carryMass = 0.0f;
		initialized = false;
		isMothership = false;
		isStation = false;
		isMiniStation = false;
		isSecondaryCore = false;
		@centerBlock = null;
		soundsPlayed = 0;
		owner = "";
	}
};

shared class ShipBlock
{
	u16 blobID;
	Vec2f offset;
	f32 angle_offset;
};

Ship@ getShip(const int colorIndex)
{
	Ship[]@ ships;
	if (getRules().get("ships", @ships))
	{
		if (colorIndex > 0 && colorIndex <= ships.length)
		{
			return ships[colorIndex-1];
		}
	}
	return null;
}

Ship@ getShip(CBlob@ this) //reference a ship from a non-block (e.g human)
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
            	return getShip(color);
            }
		}
	}
    return null;
}

CBlob@ getShipBlob(CBlob@ this) //Gets the block blob wherever 'this' is positioned
{
	CBlob@ b = null;
	f32 mDist = 9999;
	CBlob@[] blobsInRadius;	   
	if (getMap().getBlobsInRadius(this.getPosition(), 1.0f, @blobsInRadius))
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

string getCaptainName(u8 team) //Gets the name of the mothership's captain
{
	CBlob@ core = getMothership(team);
	if (core !is null)
	{
		Ship@ ship = getShip(core.getShape().getVars().customData);
		if (ship !is null && ship.owner != "")
			return ship.owner;
	}
	return "";
}

bool blocksOverlappingShip(CBlob@[]@ blocks)
{
    for (uint i = 0; i < blocks.length; ++i)
    {
        CBlob @block = blocks[i];
        if (blockOverlappingShip(block))
            return true;
    }
    return false; 
}

bool blockOverlappingShip(CBlob@ blob)
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

bool coreLinkedDirectional(CBlob@ this, u16 token, Vec2f corePos)//checks if the block leads up to a core. doesn't follow up couplings/repulsors. accounts for core position
{
	if (this.hasTag("mothership"))
		return true;

	this.set_u16("checkToken", token);
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
					optimal.insertAt(0, b);
					minDist2 = minDist;	
					minDist = coreDist;
				}
				else if (coreDist <= minDist2)
				{
					optimal.insertAt(0, b);
					minDist2 = coreDist;
				}
				else
					optimal.push_back(b);
			}
		}
		
		for (int i = 0; i < optimal.length; i++)
		{
			//print((optimal[i].hasTag("mothership") ? "[>] " : "[o] ") + optimal[i].getNetworkID());
			if (coreLinkedDirectional(optimal[i], token, corePos))
			{
				childsLinked = true;
				break;
			}
		}
	}
		
	return childsLinked;
}
