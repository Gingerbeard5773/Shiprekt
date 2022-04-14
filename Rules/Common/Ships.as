#include "ShipsCommon.as";
#include "AccurateSoundPlay.as";
#include "TileCommon.as";
#include "BlockHooks.as";

const f32 VEL_DAMPING = 0.96f; //0.96
const f32 ANGLE_VEL_DAMPING = 0.96; //0.96
const uint FORCE_UPDATE_TICKS = 21;
f32 UPDATE_DELTA_SMOOTHNESS = 32.0f;//~16-64

uint color;
void onInit(CRules@ this)
{
	Ship[] ships;
	this.set("ships", ships);
	Ship[] dirtyShips;
	this.set("dirtyShips", dirtyShips);
	CBlob@[][] dirtyBlocks;
	this.set("dirtyBlocks", dirtyBlocks);
	this.addCommandID("ships sync");
	this.addCommandID("ships update");
	this.set_s32("ships id", 0);
	this.set_bool("dirty ships", true);
}

void onRestart(CRules@ this)
{
	this.clear("ships");
	this.set_bool("dirty ships", true);
}

void onTick(CRules@ this)
{
	bool full_sync = false;				
	if (isServer())
	{
		const int time = getMap().getTimeSinceStart();
		if (time < 2) // errors are generated when done on first game tick
			return;
			
		//dirtyShips & dirtyBlocks is not required! both are done for performance improvement!
			
		// seperate a ship into two or more ships
		Ship[]@ dirtyShips;
		if (this.get("dirtyShips", @dirtyShips) && dirtyShips.length > 0)
		{
			if (!this.get_bool("dirty ships"))
			{
				for (uint i = 0; i < dirtyShips.length; i++)
				{
					SeperateShip(this, dirtyShips[i]);
				}
			}
			full_sync = true;
			this.clear("dirtyShips");
		}
		
		// add placed blocks onto an existing ship, does dirty ships if there is no ship to copy onto
		CBlob@[][]@ dirtyBlocks;
		if (this.get("dirtyBlocks", @dirtyBlocks) && dirtyBlocks.length > 0)
		{
			if (!this.get_bool("dirty ships"))
			{
				for (uint i = 0; i < dirtyBlocks.length; i++)
				{
					if (!AddToShip(dirtyBlocks[i]))
					{
						this.set_bool("dirty ships", true);
						break;
					}
				}
			}
			full_sync = true;
			this.clear("dirtyBlocks");
		}
		
		// remove existing ships and create new ones in their place, this is a full reset
		if (this.get_bool("dirty ships"))
		{
			GenerateShips(this);
			full_sync = true;
			this.set_bool("dirty ships", false);
		}

		UpdateShips(this, true, full_sync);
		Synchronize(this, full_sync);
	}
	else
		UpdateShips(this);//client-side integrate
}

bool AddToShip(CBlob@[] blocks) //reference from nearby block and copy onto ship
{
	Ship@[] touchingShips;
	//grab ships from adjacent blocks
	for (uint i = 0; i < blocks.length; i++)
	{
		CBlob@ block = blocks[i];
		
		CBlob@[] overlapping;
		#ifdef STAGING //use blobsinradius for staging since getOverlapping doesn't work on staging
			getMap().getBlobsInRadius(block.getPosition(), 8.0f, @overlapping);
		#endif
		#ifndef STAGING
			block.getOverlapping(@overlapping);
		#endif
		
		for (uint q = 0; q < overlapping.length; q++)
		{
			CBlob@ b = overlapping[q];
			Ship@ ship = getShip(b.getShape().getVars().customData);
			if (ship is null || (b.getPosition() - block.getPosition()).LengthSquared() > 78)
				continue;
				
			//shitty algorithm to make sure there is no duplicates
			bool pushShip = true;
			for (uint p = 0; p < touchingShips.length; p++)
			{
				if (ship.id == touchingShips[p].id)
				{
					pushShip = false;
					break;
				}
			}
			if (pushShip)
				touchingShips.push_back(ship);
		}
	}
	
	if (touchingShips.length != 1)
		return false; //create new ship or combine existing ships
	
	Ship@ ship = touchingShips[0];
	if (ship.centerBlock is null)
		return false;
		
	int shipColor = ship.centerBlock.getShape().getVars().customData;
	
	//set block information
	for (uint i = 0; i < blocks.length; i++)
	{
		CBlob@ block = blocks[i];
		
		ShipBlock ship_block;
		ship_block.blobID = block.getNetworkID();
		ship.blocks.push_back(ship_block);
	
		block.getShape().getVars().customData = shipColor;	
		block.set_u16("last color", shipColor);
	
		//Activate hook onColored for all blobs that have it (server)
		BlockHooks@ blockHooks;
		block.get("BlockHooks", @blockHooks);
		if (blockHooks !is null)
			blockHooks.update("onColored", @block);
	}
	
	SetUpdateSeatArrays(shipColor);
	@ship.centerBlock = null; //reset ship so positions update
	StoreVelocities(ship);

	return true;
}

void GenerateShips(CRules@ this)
{
	Ship[]@ ships;
	this.get("ships", @ships);
	for (uint i = 0; i < ships.length; ++i)
	{
		StoreVelocities(ships[i]);
	}
	
	CBlob@[] blocks;
	this.clear("ships");
	if (getBlobsByTag("block", @blocks))
	{	
		color = 0;
		for (uint i = 0; i < blocks.length; ++i)
		{
			if (blocks[i].getShape().getVars().customData > 0)
				blocks[i].getShape().getVars().customData = 0;			
		}

		for (uint i = 0; i < blocks.length; ++i)
		{
			CBlob@ b = blocks[i];
			if (b.getShape().getVars().customData == 0)
			{
				color++;

				Ship ship;
				SetNextId(this, @ship);
				this.push("ships", ship);
				Ship@ p_ship;
				this.getLast("ships", @p_ship);
				
				ColorBlocks(b, p_ship, color);
				SetUpdateSeatArrays(color);
			}
		}	
		for (uint i = 0; i < blocks.length; ++i)
		{
			CBlob@ b = blocks[i];
			b.set_u16("last color", b.getShape().getVars().customData);				
		}
	}

	//print("Generated " + color + " ships");
}

void SeperateShip(CRules@ this, Ship@ ship)
{
	StoreVelocities(ship);
	
	CBlob@[] blocks;
	for (uint i = 0; i < ship.blocks.length; ++i)
	{
		CBlob@ block = getBlobByNetworkID(ship.blocks[i].blobID);
		if (block !is null)
			blocks.push_back(block);
	}
	
	if (blocks.length <= 0) return;
	
	CBlob@ refBlock = blocks[0];
	int referenceCol = refBlock.getShape().getVars().customData;
	
	for (uint i = 0; i < blocks.length; ++i)
	{
		if (blocks[i].getShape().getVars().customData > 0)
			blocks[i].getShape().getVars().customData = 0;			
	}

	for (uint i = 0; i < blocks.length; ++i)
	{
		CBlob@ b = blocks[i];
		if (b.getShape().getVars().customData == 0)
		{
			Ship newShip;
			SetNextId(this, @newShip);
			Ship@ p_ship;
			uint newCol;
			if (b is refBlock)
			{
				newCol = referenceCol;
				this.setAt("ships", referenceCol - 1, newShip);
				this.getAt("ships", referenceCol - 1, @p_ship);
			}
			else
			{
				color++;
				newCol = color;
				this.push("ships", newShip);
				this.getLast("ships", @p_ship);
			}
			
			ColorBlocks(b, p_ship, newCol);
			SetUpdateSeatArrays(newCol);
		}
	}	
	for (uint i = 0; i < blocks.length; ++i)
	{
		CBlob@ b = blocks[i];
		b.set_u16("last color", b.getShape().getVars().customData);				
	}
}

void ColorBlocks(CBlob@ this, Ship@ ship, uint newcolor)
{
	this.getShape().getVars().customData = newcolor;
	ShipBlock ship_block;
	ship_block.blobID = this.getNetworkID();
	ship.blocks.push_back(ship_block);
	
	if (this.get_u16("last color") != this.getShape().getVars().customData)
	{
		//Activate hook onColored for all blobs that have it (server)
		BlockHooks@ blockHooks;
		this.get("BlockHooks", @blockHooks);
		if (blockHooks !is null)
			blockHooks.update("onColored", @this);
	}
	
	CBlob@[] overlapping;
	#ifdef STAGING //use blobsinradius for staging since getOverlapping doesn't work on staging
		getMap().getBlobsInRadius(this.getPosition(), 8.0f, @overlapping);
	#endif
	#ifndef STAGING
		this.getOverlapping(@overlapping);
	#endif
	
	for (uint i = 0; i < overlapping.length; i++)
	{
		CBlob@ b = overlapping[i];
		
		if (b.getShape().getVars().customData == 0 && b.hasTag("block")
			&& ((b.getPosition() - this.getPosition()).LengthSquared() < 78 || (b.getPosition() - this.getPosition()).LengthSquared() > 230)// avoid "corner" overlaps
			&& ((b.get_u16("last color") == this.get_u16("last color")) || (b.hasTag("coupling")) || (this.hasTag("coupling")) 
			|| ((getGameTime() - b.get_u32("placedTime")) < 10) || ((getGameTime() - this.get_u32("placedTime")) < 10) 
			|| (getMap().getTimeSinceStart() < 100)))
		{
			ColorBlocks(b, ship, newcolor); 
		}
	}
}

void InitShip(Ship @ship)//called for all ships after a block is placed or collides
{
	Vec2f center, vel;
	f32 angle_vel = 0.0f;
	if (ship.centerBlock is null)//when clients InitShip(), they should have key values pre-synced. no need to calculate
	{
		//get ship vels (stored previously on all blobs), center
		for (uint i = 0; i < ship.blocks.length; ++i)
		{
			CBlob@ b = getBlobByNetworkID(ship.blocks[i].blobID);
			if (b !is null)
			{
				center += b.getPosition();
				if (b.getVelocity().LengthSquared() > 0.0f)
				{
					vel = b.getVelocity();
					angle_vel = b.getAngularVelocity();			
				}
			}
		}
		center /= float(ship.blocks.length);

		//find center block and mass and if it's mothership
		f32 totalMass = 0.0f;
		f32 maxDistance = 999999.9f;
		bool choseCenterBlock = false;
		if (ship.blocks.length == 2) //choose engine as centerblock for 2 block torpedos
		{
			for (uint i = 0; i < ship.blocks.length; ++i) //shitty fix for torpedo bouncing
			{
				CBlob@ b = getBlobByNetworkID(ship.blocks[i].blobID);
				if (b !is null && b.hasTag("engine"))
				{
					choseCenterBlock = true;
					@ship.centerBlock = b;
					break;
				}
			}
		}
		for (uint i = 0; i < ship.blocks.length; ++i)
		{
			CBlob@ b = getBlobByNetworkID(ship.blocks[i].blobID);
			if (b !is null)
			{
				Vec2f vec = b.getPosition() - center;
				f32 dist = vec.LengthSquared();
				if (dist < maxDistance && !choseCenterBlock)
				{
					maxDistance = dist;
					@ship.centerBlock = b;
				}
				//mass calculation
				totalMass += b.get_f32("weight");
				
				if (b.hasTag("mothership"))
					ship.isMothership = true;
					
				if (b.hasTag("station"))
					ship.isStation = true;

				if (b.hasTag("secondaryCore"))
					ship.isSecondaryCore = true;
			}
		}
		
		ship.mass = totalMass;//linear mass growth
		ship.vel = vel;
		ship.angle_vel = angle_vel;
		if (ship.centerBlock !is null)
		{
			ship.angle = ship.centerBlock.getAngleDegrees();
			ship.pos = ship.centerBlock.getPosition();
		}
	}
	
	if (ship.centerBlock is null)
	{
		if (!isClient())
			warn("ship.centerBlock is null");
		return;
	}

	center = ship.centerBlock.getPosition();
	//print(ship.id + " mass: " + totalMass + "; effective: " + ship.mass);
	
	//update block positions/angle array
	for (uint i = 0; i < ship.blocks.length; ++i)
	{
		ShipBlock@ ship_block = ship.blocks[i];
		CBlob@ b = getBlobByNetworkID(ship_block.blobID);
		if (b !is null)
		{
			ship_block.offset = b.getPosition() - center;
			ship_block.offset.RotateBy(-ship.angle);
			ship_block.angle_offset = loopAngle(b.getAngleDegrees() - ship.angle);
		}
	}
}

void UpdateShips(CRules@ this, const bool integrate = true, const bool forceOwnerSearch = false)
{
	CMap@ map = getMap();
	
	Ship[]@ ships;
	this.get("ships", @ships);	
	for (uint i = 0; i < ships.length; ++i)
	{
		Ship@ ship = ships[i];
		if (ship.blocks.length == 0)
			continue;

		ship.soundsPlayed = 0;
		ship.carryMass = 0;
		
		if (!ship.initialized || ship.centerBlock is null)
		{
			//if (!isServer()) print ("client: initializing ship: " + ship.blocks.length);
			InitShip(ship);
			ship.initialized = true;
		}

		if (integrate && !ship.isStation)
		{
			ship.old_pos = ship.pos;
			ship.old_angle = ship.angle;
			ship.pos += ship.vel;		
			ship.angle += ship.angle_vel;
			ship.vel *= VEL_DAMPING;
			ship.angle_vel *= ANGLE_VEL_DAMPING;
			
			//check for beached or slowed ships
			
			int beachedBlocks = 0;
			int slowedBlocks = 0;
			
			for (uint q = 0; q < ship.blocks.length; ++q)
			{
				ShipBlock@ ship_block = ship.blocks[q];
				CBlob@ b = getBlobByNetworkID(ship_block.blobID);
				if (b !is null)
				{
					Vec2f bPos = b.getPosition();	
					Tile bTile = map.getTile(bPos);
					
					if (map.isTileSolid(bTile) && bPos.Length() > 15.0f) //are we on rock
					{
						TileCollision(ship, bPos);
						if (!b.hasTag("mothership") || this.get_bool("whirlpool"))
							b.server_Hit(b, bPos, Vec2f_zero, 1.0f, 0, true);
					}
					else if (isTouchingLand(bPos))
						beachedBlocks++;
					else if (isTouchingShoal(bPos))
						slowedBlocks++;
				}
			}
			
			if (beachedBlocks > 0)
			{
				f32 velocity = Maths::Clamp(beachedBlocks / ship.mass, 0.0f, 0.4f);
				ship.vel *= 1.0f - velocity;
				ship.angle_vel *= 1.0f - velocity;
			}
			else if (slowedBlocks > 0)
			{
				f32 velocity = Maths::Clamp(slowedBlocks / (ship.mass * 2), 0.0f, 0.08f);
				ship.vel *= 1.0f - velocity;
				ship.angle_vel *= 1.0f - velocity;
			}

			ship.angle = loopAngle(ship.angle);
		}
		else if (ship.isStation)
		{
			ship.vel = Vec2f(0, 0);
			ship.angle_vel = 0.0f;			
		}

		if (!isServer() || (!forceOwnerSearch && (getGameTime() + ship.id * 33) % 45 > 0))//updateShipBlobs if !isServer OR isServer and not on a 'second tick'
		{
			for (uint q = 0; q < ship.blocks.length; ++q)
			{
				ShipBlock@ ship_block = ship.blocks[q];
				CBlob@ b = getBlobByNetworkID(ship_block.blobID);
				if (b !is null)
				{
					UpdateShipBlob(b, ship, ship_block);
				}
			}
		}
		else //(server) updateShipBlobs and find ship.owner once a second or after GenerateShips()
		{
			u8 cores = 0;
			CBlob@ core = null;
			bool multiTeams = false;
			s8 teamComp = -1;	
			u16[] seatIDs;
			
			for (uint q = 0; q < ship.blocks.length; ++q)
			{
				ShipBlock@ ship_block = ship.blocks[q];
				CBlob@ b = getBlobByNetworkID(ship_block.blobID);
				if (b !is null)
				{
					UpdateShipBlob(b, ship, ship_block);
					
					if (b.hasTag("control") && b.get_string("playerOwner") != "")
					{
						seatIDs.push_back(ship_block.blobID);
						
						if (teamComp == -1)
							teamComp = b.getTeamNum();
						else if (b.getTeamNum() != teamComp)
							multiTeams = true;
					} 
					else if (b.hasTag("mothership"))
					{
						cores++;
						@core = b;
					}
				}
			}
			
			string oldestSeatOwner = "";
			
			if (seatIDs.length > 0)
			{
				seatIDs.sortAsc();
				if (ship.isMothership)
				{
					if (cores > 1 && multiTeams)
						oldestSeatOwner = "*";
					else if (core !is null)
					{
						for (int q = 0; q < seatIDs.length; q++)
						{
							CBlob@ oldestSeat = getBlobByNetworkID(seatIDs[q]);
							if (oldestSeat !is null && coreLinkedDirectional(oldestSeat, getGameTime(), core.getPosition()))
							{
								oldestSeatOwner = oldestSeat.get_string("playerOwner");
								break;
							}
						}
					}
				}
				else
				{
					if (multiTeams)
						oldestSeatOwner = "*";
					else
					{
						for (int q = 0; q < seatIDs.length; q++)
						{
							CBlob@ oldestSeat = getBlobByNetworkID(seatIDs[q]);
							if (oldestSeat !is null)
							{
								oldestSeatOwner = oldestSeat.get_string("playerOwner");
								break;
							}
						}
					}
				}
			}
			
			//change ship color (only non-motherships that have activated seats)
			if (!ship.isMothership && !ship.isStation && !multiTeams && oldestSeatOwner != "" && ship.owner != oldestSeatOwner)
			{
				CPlayer@ iOwner = getPlayerByUsername(oldestSeatOwner);
				if (iOwner !is null)
					SetShipTeam(ship, iOwner.getTeamNum());
			}
			
			ship.owner = oldestSeatOwner;
		}
		//if (ship.owner != "") print("updated ship " + ship.id + "; owner: " + ship.owner + "; mass: " + ship.mass);
	}
	
	//calculate carryMass weight
	CBlob@[] humans;
	getBlobsByName("human", @humans);
	for (u8 i = 0; i < humans.length; i++)
	{
	    CBlob@[]@ blocks;
		if (humans[i].get("blocks", @blocks) && blocks.size() > 0)
		{
			Ship@ ship = getShip(humans[i]);
			if (ship !is null)
			{
				//player-carried blocks add to the ship mass (with penalty)
				for (u8 q = 0; q < blocks.length; q++)
					ship.carryMass += 2.5f * blocks[q].get_f32("weight");
			}
		}
	}
}

void UpdateShipBlob(CBlob@ blob, Ship @ship, ShipBlock@ ship_block)
{
	Vec2f offset = ship_block.offset;
	offset.RotateBy(ship.angle);
		
	blob.setPosition(ship.pos + offset);
	blob.setAngleDegrees(ship.angle + ship_block.angle_offset);

	//don't collide with borders
	blob.setVelocity(Vec2f_zero);
	blob.setAngularVelocity(0.0f);
}

void TileCollision(Ship@ ship, Vec2f tilePos)
{
	if (ship is null)
		return;
		
	if (ship.mass <= 0)
		return;
	
	Vec2f velnorm = ship.vel; 
	const f32 vellen = velnorm.Normalize();
	
	Vec2f colvec1 = tilePos - ship.pos;
	colvec1.Normalize();
	
	ship.vel = -colvec1*1.0f;
	
	//effects
	int shake = vellen * ship.mass;
	ShakeScreen(Maths::Min(shake, 120), 12, tilePos);
	directionalSoundPlay(shake > 25 ? "WoodHeavyBump" : "WoodLightBump", tilePos);
}

void SetNextId(CRules@ this, Ship@ ship)
{
	this.add_s32("ships id", 1);
	ship.id = this.get_s32("ships id");
}

void SetShipTeam(Ship@ ship, u8 teamNum = 255)
{
	//print ("setting team for " + ship.owner + "'s " + ship.id + " to " + teamNum);
	for (uint i = 0; i < ship.blocks.length; ++i)
	{
		CBlob@ b = getBlobByNetworkID(ship.blocks[i].blobID);
		if (b !is null)
		{
			b.server_setTeamNum(teamNum);
		}
	}
}

void StoreVelocities(Ship@ ship)
{	
	if (!ship.isStation)
	{
		for (uint i = 0; i < ship.blocks.length; ++i)
		{
			CBlob@ b = getBlobByNetworkID(ship.blocks[i].blobID);
			if (b !is null)
			{
				b.setVelocity(ship.vel);
				b.setAngularVelocity(ship.angle_vel);	
			}
		}
	}
}

void SetUpdateSeatArrays(int shipColor)
{
	CBlob@[] seats;
	if (getBlobsByTag("seat", @seats))
	{
		for (uint i = 0; i < seats.length; i++)
		{
			if (seats[i].getShape().getVars().customData == shipColor)
				seats[i].set_bool("updateArrays", true);
		}
	}
}

void onBlobChangeTeam(CRules@ this, CBlob@ blob, const int oldTeam)//awkward fix for blob team changes wiping up the frame state (rest on Block.as)
{
	if (!isServer() && blob.hasTag("block") && blob.getSprite().getFrame() > 0)
		blob.set_u8("frame", blob.getSprite().getFrame());
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	// this will leave holes until next full sync
	int blobColor = blob.getShape().getVars().customData;
	if (blobColor > 0)
	{
		const u16 id = blob.getNetworkID();
		Ship@ ship = getShip(blobColor);
		if (ship !is null)
		{
			for (uint i = 0; i < ship.blocks.length; ++i)
			{
				if (ship.blocks[i].blobID == id)
				{
					ship.blocks.erase(i); 
					if (ship.centerBlock is null || ship.centerBlock.getNetworkID() == id)
					{
						@ship.centerBlock = null;
						ship.initialized = false;
					}
					i = 0;
				}
			}
			
			if (isServer() && !blob.hasTag("activated"))
			{
				bool pushShip = true;
				
				//dont push duplicates
				Ship[]@ dirtyShips;
				this.get("dirtyShips", @dirtyShips);
				for (uint i = 0; i < dirtyShips.length; i++)
				{
					if (ship.id == dirtyShips[i].id)
					{
						pushShip = false;
						break;
					}
				}
				
				if (ship.blocks.length > 1 && pushShip)
					this.push("dirtyShips", ship); //seperate an island
			}
		}
	}
}

// network

void Synchronize(CRules@ this, bool full_sync, CPlayer@ player = null)
{
    CBitStream bs;
    if (Serialize(this, bs, full_sync))
    {
        if (player is null)
        {
            this.SendCommand(full_sync ? this.getCommandID("ships sync") : this.getCommandID("ships update"), bs);
        }
        else
        {
            this.SendCommand(full_sync ? this.getCommandID("ships sync") : this.getCommandID("ships update"), bs, player);
        }
    }
}

bool Serialize(CRules@ this, CBitStream@ stream, const bool full_sync)
{
	Ship[]@ ships;
	if (this.get("ships", @ships))
	{
		stream.write_u16(ships.length);
		bool atLeastOne = false;
		for (uint i = 0; i < ships.length; ++i)
		{
			Ship @ship = ships[i];
			if (full_sync)
			{
				stream.write_Vec2f(ship.pos);
				CPlayer@ owner = getPlayerByUsername(ship.owner);
				stream.write_netid(owner !is null ? owner.getNetworkID() : 0);
				stream.write_netid(ship.centerBlock !is null ? ship.centerBlock.getNetworkID() : 0);
				stream.write_Vec2f(ship.vel);
				stream.write_f32(ship.angle);
				stream.write_f32(ship.angle_vel);			
				stream.write_f32(ship.mass);
				stream.write_bool(ship.isMothership);
				stream.write_bool(ship.isStation);
				stream.write_bool(ship.isSecondaryCore);
				stream.write_u16(ship.blocks.length);
				for (uint q = 0; q < ship.blocks.length; ++q)
				{
					ShipBlock@ ship_block = ship.blocks[q];
					CBlob@ b = getBlobByNetworkID(ship_block.blobID);
					if (b !is null)
					{
						stream.write_netid(b.getNetworkID());	
						stream.write_Vec2f(ship_block.offset);
						stream.write_f32(ship_block.angle_offset);
					}
					else
					{
						stream.write_netid(0);	
						stream.write_Vec2f(Vec2f_zero);
						stream.write_f32(0.0f);
					}
				}
				ship.net_pos = ship.pos;		
				ship.net_vel = ship.vel;
				ship.net_angle = ship.angle;
				ship.net_angle_vel = ship.angle_vel;
				atLeastOne = true;
			}
			else
			{
				const f32 thresh = 0.005f;
				if ((getGameTime()+i) % FORCE_UPDATE_TICKS == 0 || isShipChanged(ship))				
				{
					stream.write_bool(true);
					CPlayer@ owner = getPlayerByUsername(ship.owner);
					stream.write_netid(owner !is null ? owner.getNetworkID() : 0);			
					if ((ship.net_pos - ship.pos).LengthSquared() > thresh)
					{
						stream.write_bool(true);
						stream.write_Vec2f(ship.pos);
						ship.net_pos = ship.pos;
					}
					else stream.write_bool(false);

					if ((ship.net_vel - ship.vel).LengthSquared() > thresh)
					{
						stream.write_bool(true);
						stream.write_Vec2f(ship.vel);
						ship.net_vel = ship.vel;
					}
					else stream.write_bool(false);
					
					if (Maths::Abs(ship.net_angle - ship.angle) > thresh)
					{
						stream.write_bool(true);
						stream.write_f32(ship.angle);
						ship.net_angle = ship.angle;
					}
					else stream.write_bool(false);

					if (Maths::Abs(ship.net_angle_vel - ship.angle_vel) > thresh)
					{
						stream.write_bool(true);
						stream.write_f32(ship.angle_vel);
						ship.net_angle_vel = ship.angle_vel;
					}
					else stream.write_bool(false);

					atLeastOne = true;		
				}
				else
					stream.write_bool(false);
			}
		}
		return atLeastOne;
	}
	
	warn("ships not found on serialize");
	return false;
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (isServer()) return;

	if (cmd == this.getCommandID("ships sync"))
	{
		Ship[]@ ships;
		if (this.get("ships", @ships))
		{
			ships.clear();
			const u16 count = params.read_u16();
			for (uint i = 0; i < count; ++i)
			{
				Ship ship;
				if (!params.saferead_Vec2f(ship.pos))
				{
					warn("ships sync: ship.pos not found");
					return;
				}
				u16 ownerID = params.read_netid();
				CPlayer@ owner = ownerID != 0 ? getPlayerByNetworkId(ownerID) : null;
				ship.owner = owner !is null ? owner.getUsername() : "";
				u16 centerBlockID = params.read_netid();
				@ship.centerBlock = centerBlockID != 0 ? getBlobByNetworkID(centerBlockID) : null;
				ship.vel = params.read_Vec2f();
				ship.angle = params.read_f32();
				ship.angle_vel = params.read_f32();
				ship.mass = params.read_f32();
				ship.isMothership = params.read_bool();
				ship.isStation = params.read_bool();
				ship.isSecondaryCore = params.read_bool();
				if (ship.centerBlock !is null)
				{
					ship.initialized = true;
					if (ship.vel.LengthSquared() > 0.01f)//try to use local values to smoother sync
					{
						ship.pos = ship.centerBlock.getPosition();
						ship.angle = ship.centerBlock.getAngleDegrees();
					}
				}
				ship.old_pos = ship.pos;
				ship.old_angle = ship.angle;
				
				const u16 blocks_count = params.read_u16();
				for (uint q = 0; q < blocks_count; ++q)
				{
					u16 netid;
					if (!params.saferead_netid(netid))
					{
						warn("ships sync: netid not found");
						return;
					}
					CBlob@ b = getBlobByNetworkID(netid);
					Vec2f pos = params.read_Vec2f();
					f32 angle = params.read_f32();
					if (b !is null)
					{
						ShipBlock ship_block;
						ship_block.blobID = netid;
						ship_block.offset = pos;
						ship_block.angle_offset = angle;
						ship.blocks.push_back(ship_block);	
	    				b.getShape().getVars().customData = i+1; // color
						
						if (b.get_u16("last color") != b.getShape().getVars().customData)
						{
							//Activate hook onColored for all blobs that have it (client)
							BlockHooks@ blockHooks;
							b.get("BlockHooks", @blockHooks);
							if (blockHooks !is null)
								blockHooks.update("onColored", @b);
						}

						// safety on desync
						b.SetVisible(true);
						CSprite@ sprite = b.getSprite();
						sprite.asLayer().SetColor(color_white);
						sprite.asLayer().setRenderStyle(RenderStyle::normal);
					}
					else
						warn("Blob not found when creating ship, id = " + netid);
				}
				ships.push_back(ship);
			}

			UpdateShips(this, false);
		}
		else
		{
			warn("Ships not found on sync");
			return;
		}
	}
	else if (cmd == this.getCommandID("ships update"))
	{
		Ship[]@ ships;
		if (this.get("ships", @ships))
		{
			u16 count;
			if (!params.saferead_u16(count))
			{
				warn("ships update: count not found");
				return;
			}
			if (count != ships.length)
			{
				//onNewPlayerJoin is called with a delay after a player joins, which triggers this warning
				if (sv_test)
					warn("Update received before ship sync " + count + " != " + ships.length);
				return;
			}
			for (uint i = 0; i < count; ++i)
			{
				if (params.read_bool())
				{
					Ship @ship = ships[i];
					u16 ownerID = params.read_netid();
					CPlayer@ owner = ownerID != 0 ? getPlayerByNetworkId(ownerID) : null;
					ship.owner = owner !is null ? owner.getUsername() : "";
					if (params.read_bool())
					{
						Vec2f dDelta = params.read_Vec2f() - ship.pos;
						if (dDelta.LengthSquared() < 512)//8 blocks threshold
							ship.pos = ship.pos + dDelta/UPDATE_DELTA_SMOOTHNESS;
						else
							ship.pos += dDelta; 
					}
					if (params.read_bool())
					{
						ship.vel = params.read_Vec2f()/VEL_DAMPING;
					}
					if (params.read_bool())
					{
						f32 aDelta =  params.read_f32() - ship.angle;
						if (aDelta > 180)	aDelta -= 360;
						if (aDelta < -180)	aDelta += 360;
						ship.angle = loopAngle(ship.angle + aDelta/UPDATE_DELTA_SMOOTHNESS);
					}
					if (params.read_bool())
					{
						ship.angle_vel = params.read_f32()/ANGLE_VEL_DAMPING;
					}
				}
			}
			//no need to UpdateShips()
		}
		else
		{
			warn("Ships not found on update");
			return;
		}
	}
}

f32 loopAngle(f32 angle)
{
	while (angle < 0.0f)	angle += 360.0f;
	while (angle > 360.0f)	angle -= 360.0f;
	return angle;
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (!player.isMyPlayer())
		Synchronize(this, true, player); // will set old values
}

bool isShipChanged(Ship@ ship)
{
	const f32 thresh = 0.01f;
	return ((ship.pos - ship.old_pos).LengthSquared() > thresh || Maths::Abs(ship.angle - ship.old_angle) > thresh);
}

bool candy = false;
bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{	
	if (player !is null)
	{
		bool myPlayer = player.isMyPlayer();
		if (myPlayer && textIn == "!candy")
		{
			candy = !candy;
			return false;
		}
		
		if (textIn.substr(0,1) == "!")
		{
			string[]@ tokens = textIn.split(" ");

			if (tokens[0] == "!ds")
			{
				if (myPlayer)
				{
					if (tokens.length > 1)
					{
						UPDATE_DELTA_SMOOTHNESS = Maths::Max(1.0f, parseFloat(tokens[1]));
						client_AddToChat("Delta smoothness set to " + UPDATE_DELTA_SMOOTHNESS);
					}
					else
						client_AddToChat("Delta smoothness: " + UPDATE_DELTA_SMOOTHNESS);
				}
				return false;
			}
		}
	}
	
	return true;
}

void onRender(CRules@ this)
{
	//draw ship colors & block ids
	
	if (g_debug == 1 || candy)
	{
		CCamera@ camera = getCamera();
		if (camera is null) return;
		f32 camRotation = camera.getRotation();
		Ship[]@ ships;
		if (this.get("ships", @ships))
		{
			for (uint i = 0; i < ships.length; ++i)
			{
				Ship @ship = ships[i];
				if (ship.centerBlock !is null)
				{
					Vec2f cbPos = getDriver().getScreenPosFromWorldPos(ship.centerBlock.getPosition());
					Vec2f iVel = ship.vel * 20;
					iVel.RotateBy(-camRotation);					
					GUI::DrawArrow2D(cbPos, cbPos + iVel, SColor(175, 0, 200, 0));
					if (camera.targetDistance <= 1.0f)
						GUI::DrawText("" + ship.centerBlock.getShape().getVars().customData, cbPos, SColor(255,255,255,255));
					//GUI::DrawText("" + ship.vel.Length(), cbPos, SColor( 255,255,255,255));
				}
					
				for (uint i = 0; i < ship.blocks.length; ++i)
				{
					ShipBlock@ ship_block = ship.blocks[i];
					CBlob@ b = getBlobByNetworkID(ship_block.blobID);
					if (b !is null)
					{
						int c = b.getShape().getVars().customData;
						GUI::DrawRectangle(getDriver().getScreenPosFromWorldPos(b.getPosition() - Vec2f(4, 4).RotateBy(camRotation)), 
										   getDriver().getScreenPosFromWorldPos(b.getPosition() + Vec2f(4, 4).RotateBy(camRotation)), SColor(100, c*50, -c*90, 93*c));
						if (camera.targetDistance > 1.0f)
							GUI::DrawText("" + ship_block.blobID, getDriver().getScreenPosFromWorldPos(b.getPosition()), SColor(255,255,255,255));
					}
				}
			}
		}
	}
}
