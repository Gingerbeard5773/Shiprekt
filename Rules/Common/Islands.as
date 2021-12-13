#include "IslandsCommon.as"
#include "BlockCommon.as"
#include "AccurateSoundPlay.as"
#include "TileCommon.as"

const f32 VEL_DAMPING = 0.96f; //0.96
const f32 ANGLE_VEL_DAMPING = 0.96; //0.96
const uint FORCE_UPDATE_TICKS = 21;
f32 UPDATE_DELTA_SMOOTHNESS = 32.0f;//~16-64

uint color;
bool updatedThisTick = false;
void onInit(CRules@ this)
{
	Island[] islands;
	this.set("islands", islands);
	this.addCommandID("islands sync");
	this.addCommandID("islands update");
	this.set_u32("islands id", 0);
	this.set_bool("dirty islands", true);
}

void onRestart(CRules@ this)
{
	this.clear("islands");
	this.set_bool("dirty islands", true);
}

void onTick(CRules@ this)
{
	bool full_sync = false;				
	if (isServer())
	{
		const int time = getMap().getTimeSinceStart();
		if (time < 2) // errors are generated when done on first game tick
			return;

		const bool dirty = this.get_bool("dirty islands");
		if (dirty)
		{
			GenerateIslands(this);			
			setUpdateSeatsArrays();
			this.set_bool("dirty islands", false);
			full_sync = true;
		}

		UpdateIslands(this, true, full_sync);
		Synchronize(this, full_sync );
	}
	else
		UpdateIslands(this);//client-side integrate
		
	updatedThisTick = false;
}

void GenerateIslands(CRules@ this)
{
	StoreVelocities(this);

	CBlob@[] blocks;
	this.clear("islands");
	if (getBlobsByName("block", @blocks))
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

				Island island;
				SetNextId( this, @island );
				this.push("islands", island);
				Island@ p_island;
				this.getLast("islands", @p_island);

				ColorBlocks(b, p_island);			
			}
		}	
		for (uint i = 0; i < blocks.length; ++i)
		{
			CBlob@ b = blocks[i];
			b.set_u16("last color", b.getShape().getVars().customData);				
		}
	}

	//print("Generated " + color + " islands");
}

void ColorBlocks(CBlob@ blob, Island@ island)
{
	blob.getShape().getVars().customData = color;
	
	IslandBlock isle_block;
	isle_block.blobID = blob.getNetworkID();
	island.blocks.push_back(isle_block);

	CBlob@[] overlapping;
    if (blob.getOverlapping( @overlapping ))
    {
        for (uint i = 0; i < overlapping.length; i++)
        {
            CBlob@ b = overlapping[i];
			
            if (b.getShape().getVars().customData == 0 
				&& b.getName() == "block" 
				&& (b.getPosition() - blob.getPosition()).LengthSquared() < 78 // avoid "corner" overlaps
				&& ((b.get_u16("last color") == blob.get_u16("last color")) || (b.getSprite().getFrame() == Block::COUPLING) || (blob.getSprite().getFrame() == Block::COUPLING) 
				|| ((getGameTime() - b.get_u32("placedTime")) < 10) || ((getGameTime() - blob.get_u32("placedTime")) < 10) 
				|| (getMap().getTimeSinceStart() < 100)))
				{
					ColorBlocks(b, island); 
				}
        }
    }
}

void InitIsland(Island @isle)//called for all islands after a block is placed or collides
{
	Vec2f center, vel;
	f32 angle_vel = 0.0f;
	if (isle.centerBlock is null)//when clients InitIsland(), they should have key values pre-synced. no need to calculate
	{
		//get island vels (stored previously on all blobs), center
		for (uint i = 0; i < isle.blocks.length; ++i)
		{
			CBlob@ b = getBlobByNetworkID(isle.blocks[i].blobID);
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
		center /= float(isle.blocks.length);

		//find center block and mass and if it's mothership
		f32 totalMass = 0.0f;
		f32 maxDistance = 999999.9f;
		for (uint i = 0; i < isle.blocks.length; ++i)
		{
			CBlob@ b = getBlobByNetworkID(isle.blocks[i].blobID);
			if (b !is null)
			{
				Vec2f vec = b.getPosition() - center;
				f32 dist = vec.LengthSquared();
				if (dist < maxDistance)
				{
					maxDistance = dist;
					@isle.centerBlock = b;
				}
				//mass calculation
				totalMass += Block::getWeight(b);
				
				if (b.hasTag("mothership"))
					isle.isMothership = true;
					
				if (b.hasTag("station"))
					isle.isStation = true;
					
				if (b.hasTag("ministation"))
					isle.isMiniStation = true;

				if (b.hasTag("secondaryCore"))
					isle.isSecondaryCore = true;
			}
		}
		
		isle.mass = totalMass;//linear mass growth
		isle.vel = vel;
		isle.angle_vel = angle_vel;
		if (isle.centerBlock !is null)
		{
			isle.angle = isle.centerBlock.getAngleDegrees();
			isle.pos = isle.centerBlock.getPosition();
		}
	}
	
	if (isle.centerBlock is null)
	{
		if (!isClient())
			warn("isle.centerBlock is null");
		return;
	}

	center = isle.centerBlock.getPosition();
	//print( isle.id + " mass: " + totalMass + "; effective: " + isle.mass );
	
	//update block positions/angle array
	for (uint i = 0; i < isle.blocks.length; ++i)
	{
		IslandBlock@ isle_block = isle.blocks[i];
		CBlob@ b = getBlobByNetworkID(isle_block.blobID);
		if (b !is null)
		{
			isle_block.offset = b.getPosition() - center;
			isle_block.offset.RotateBy(-isle.angle);
			isle_block.angle_offset = b.getAngleDegrees() - isle.angle;
		}
	}
}

void UpdateIslands(CRules@ this, const bool integrate = true, const bool forceOwnerSearch = false)
{
	updatedThisTick = true;
	CMap@ map = getMap();
	
	Island[]@ islands;
	this.get("islands", @islands);	
	for (uint i = 0; i < islands.length; ++i)
	{
		Island @isle = islands[i];

		isle.soundsPlayed = 0;
		isle.carryMass = 0;
		
		if (!isle.initialized || isle.centerBlock is null)
		{
			//if ( !isServer() ) print ("client: initializing island: " + isle.blocks.length);
			InitIsland(isle);
			isle.initialized = true;
		}

		if (integrate && !isle.isStation && !isle.isMiniStation)
		{
			isle.old_pos = isle.pos;
			isle.old_angle = isle.angle;
			isle.pos += isle.vel;		
			isle.angle += isle.angle_vel;
			isle.vel *= VEL_DAMPING;
			isle.angle_vel *= ANGLE_VEL_DAMPING;
			
			//check for beached or slowed islands
			isle.beached = false;
			isle.slowed = false;
			for (uint q = 0; q < isle.blocks.length; ++q)
			{
				IslandBlock@ isle_block = isle.blocks[q];
				CBlob@ b = getBlobByNetworkID(isle_block.blobID);
				if (b !is null)
				{
					Vec2f bPos = b.getPosition();	
					Tile bTile = map.getTile(bPos);
					bool onLand = map.isTileBackgroundNonEmpty(bTile);
					bool onRock = map.isTileSolid(bTile);
					
					if (onRock)
					{
						TileCollision(isle, bPos);
						if (!b.hasTag("mothership") || this.get_bool("sudden death") )
							b.server_Hit( b, bPos, Vec2f_zero, 2.2f, 0, true );
					}
					else if (isTouchingLand(bPos))
						isle.beached = true;						
					else if (isTouchingShoal(bPos))
						isle.slowed = true;
				}
			}
			
			if (isle.beached)
			{
				isle.vel *= 0.25f;
				isle.angle_vel *= 0.25f;
			}
			else if (isle.slowed)
			{
				isle.vel *= 0.9f;
				isle.angle_vel *= 0.9f;
			}

			while(isle.angle < 0.0f)
				isle.angle += 360.0f;
				
			while(isle.angle > 360.0f)
				isle.angle -= 360.0f;
		}
		else if (isle.isStation || isle.isMiniStation)
		{
			isle.vel = Vec2f(0, 0);
			isle.angle_vel = 0.0f;			
		}

		if (!isServer() || (!forceOwnerSearch && (getGameTime() + isle.id * 33) % 45 > 0))//updateIslandBlobs if !isServer OR isServer and not on a 'second tick'
		{
			for (uint q = 0; q < isle.blocks.length; ++q)
			{
				IslandBlock@ isle_block = isle.blocks[q];
				CBlob@ b = getBlobByNetworkID( isle_block.blobID);
				if (b !is null)
				{
					UpdateIslandBlob(b, isle, isle_block);
				}
			}
		}
		else //(server) updateIslandBlobs and find island.owner once a second or after GenerateIslands()
		{
			u8 cores = 0;
			CBlob@ core = null;
			bool multiTeams = false;
			s8 teamComp = -1;	
			u16[] seatIDs;
			
			for (uint q = 0; q < isle.blocks.length; ++q)
			{
				IslandBlock@ isle_block = isle.blocks[q];
				CBlob@ b = getBlobByNetworkID(isle_block.blobID);
				if (b !is null)
				{
					UpdateIslandBlob(b, isle, isle_block);
					
					if (b.hasTag("control") && b.get_string("playerOwner") != "")
					{
						seatIDs.push_back( isle_block.blobID );
						
						if (teamComp == -1 )
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
				if (isle.isMothership)
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
			if (!isle.isMothership && !isle.isStation && !isle.isMiniStation && !multiTeams && oldestSeatOwner != "" && isle.owner != oldestSeatOwner)
			{
				CPlayer@ iOwner = getPlayerByUsername(oldestSeatOwner);
				if (iOwner !is null)
					setIsleTeam(isle, iOwner.getTeamNum());
			}
			
			isle.owner = oldestSeatOwner;
		}
		//if( isle.owner != "") 	print( "updated isle " + isle.id + "; owner: " + isle.owner + "; mass: " + isle.mass );
	}
	
	//calculate carryMass weight
	CBlob@[] humans;
	getBlobsByName("human", @humans);
	for (u8 i = 0; i < humans.length; i++)
	{
	    CBlob@[]@ blocks;
		if (humans[i].get("blocks", @blocks) && blocks.size() > 0)
		{
			Island@ isle = getIsland(humans[i]);
			if (isle !is null)
			{
				//player-carried blocks add to the island mass (with penalty)
				for (u8 i = 0; i < blocks.length; i++)
					isle.carryMass += 2.5f * Block::getWeight(blocks[i]);
			}
		}
	}
}

void UpdateIslandBlob(CBlob@ blob, Island @isle, IslandBlock@ isle_block)
{
	Vec2f offset = isle_block.offset;
	offset.RotateBy(isle.angle);
 	
 	blob.setPosition(isle.pos + offset);
 	blob.setAngleDegrees(isle.angle + isle_block.angle_offset);

	blob.setVelocity(Vec2f_zero);
	blob.setAngularVelocity(0.0f);
}

void TileCollision(Island@ island, Vec2f tilePos)
{
	if (island is null)
		return;
		
	if (island.mass <= 0)
		return;
	
	Vec2f velnorm = island.vel; 
	const f32 vellen = velnorm.Normalize();
	
	Vec2f colvec1 = tilePos - island.pos;
	colvec1.Normalize();

	const f32 veltransfer = 1.0f;
	const f32 veldamp = 1.0f;
	const f32 dirscale = 1.0f;
	f32 reactionScale2 = 1.0f;
	if (island.beached)
		reactionScale2 *= 2;
	island.vel *= veldamp;
	
	island.vel = -colvec1*1.0f;
	
	//effects
	int shake = (vellen * island.mass + vellen * island.mass)*0.5f;
	ShakeScreen(shake, 12, tilePos);
	directionalSoundPlay(shake > 25 ? "WoodHeavyBump" : "WoodLightBump", tilePos);
}

void setIsleTeam(Island @isle, u8 teamNum = 255)
{
	//print ("setting team for " + isle.owner + "'s " + isle.id + " to " + teamNum);
	for (uint i = 0; i < isle.blocks.length; ++i)
	{
		CBlob@ b = getBlobByNetworkID(isle.blocks[i].blobID);
		if (b !is null)
		{
			int blockType = b.getSprite().getFrame();
			b.server_setTeamNum(teamNum);
			b.getSprite().SetFrame(blockType);
		}
	}
}

void onBlobChangeTeam(CRules@ this, CBlob@ blob, const int oldTeam)//awkward fix for blob team changes wiping up the frame state (rest on Block.as)
{
	if (!isServer() && blob.getName() == "block")
		blob.set_u8("frame", blob.getSprite().getFrame());
}

void StoreVelocities(CRules@ this)
{
	Island[]@ islands;
	if (this.get("islands", @islands))
	{
		for (uint i = 0; i < islands.length; ++i)
		{
			Island @isle = islands[i];
			
			if (!isle.isStation && !isle.isMiniStation)
			{
				for (uint q = 0; q < isle.blocks.length; ++q)
				{
					CBlob@ b = getBlobByNetworkID(isle.blocks[q].blobID);
					if (b !is null)
					{
						b.setVelocity(isle.vel);
						b.setAngularVelocity(isle.angle_vel);	
					}
				}
			}
		}
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	// this will leave holes until next full sync
	if (blob.getShape().getVars().customData > 0)
	{
		const u16 id = blob.getNetworkID();
		Island@ isle = getIsland(blob.getShape().getVars().customData);
		if (isle !is null)
		{
			for (uint i = 0; i < isle.blocks.length; ++i)
			{
				if (isle.blocks[i].blobID == id)
				{
					isle.blocks.erase(i); 
					if (isle.centerBlock is null || isle.centerBlock.getNetworkID() == id)
					{
						@isle.centerBlock = null;
						isle.initialized = false;
					}
					i = 0;

					if (blob.getSprite().getFrame() == Block::COUPLING)
					{
						this.set_bool("dirty islands", true);		
						return;
					}
				}
			}
			//if (isle.blocks.length == 0)
				this.set_bool("dirty islands", true);			
		}
	}
}

void setUpdateSeatsArrays()
{
	CBlob@[] seats;
	if (getBlobsByTag("seat", @seats))
	{
		for (uint i = 0; i < seats.length; i++ )
		{
			seats[i].set_bool("updateArrays", true);
		}
	}
}


// network

void Synchronize(CRules@ this, bool full_sync, CPlayer@ player = null)
{
    CBitStream bs;
    if (Serialize(this, bs, full_sync))
    {
        if (player == @null)
        {
            for (u16 i = 0; i < getPlayerCount(); i++)
            {
                this.SendCommand(full_sync ? this.getCommandID("islands sync") : this.getCommandID("islands update"), bs, getPlayer(i));
            }
        }
        else
        {
            this.SendCommand(full_sync ? this.getCommandID("islands sync") : this.getCommandID("islands update"), bs, player);
        }
    }
}

bool Serialize(CRules@ this, CBitStream@ stream, const bool full_sync)
{
	Island[]@ islands;
	if (this.get("islands", @islands))
	{
		stream.write_u16(islands.length);
		bool atLeastOne = false;
		for (uint i = 0; i < islands.length; ++i)
		{
			Island @isle = islands[i];
			if (full_sync)
			{
				stream.write_Vec2f(isle.pos);
				CPlayer@ owner = getPlayerByUsername(isle.owner);
				stream.write_u16(owner !is null ? owner.getNetworkID() : 0);
				stream.write_u16(isle.centerBlock !is null ? isle.centerBlock.getNetworkID() : 0);
				stream.write_Vec2f(isle.vel);
				stream.write_f32(isle.angle);
				stream.write_f32(isle.angle_vel);			
				stream.write_f32(isle.mass);
				stream.write_bool(isle.isMothership);
				stream.write_bool(isle.isStation);
				stream.write_bool(isle.isMiniStation);
				stream.write_bool(isle.isSecondaryCore);
				stream.write_u16(isle.blocks.length);
				for (uint q = 0; q < isle.blocks.length; ++q)
				{
					IslandBlock@ isle_block = isle.blocks[q];
					CBlob@ b = getBlobByNetworkID( isle_block.blobID);
					if (b !is null)
					{
						stream.write_netid(b.getNetworkID());	
						stream.write_Vec2f(isle_block.offset);
						stream.write_f32(isle_block.angle_offset);
					}
					else
					{
						stream.write_netid(0);	
						stream.write_Vec2f(Vec2f_zero);
						stream.write_f32(0.0f);
					}
				}
				isle.net_pos = isle.pos;		
				isle.net_vel = isle.vel;
				isle.net_angle = isle.angle;
				isle.net_angle_vel = isle.angle_vel;
				atLeastOne = true;
			}
			else
			{
				const f32 thresh = 0.005f;
				if ((getGameTime()+i) % FORCE_UPDATE_TICKS == 0 || isIslandChanged(isle))				
				{
					stream.write_bool(true);
					CPlayer@ owner = getPlayerByUsername(isle.owner);
					stream.write_u16( owner !is null ? owner.getNetworkID() : 0);			
					if ((isle.net_pos - isle.pos).LengthSquared() > thresh)
					{
						stream.write_bool(true);
						stream.write_Vec2f(isle.pos);
						isle.net_pos = isle.pos;
					}
					else stream.write_bool(false);

					
					if ((isle.net_vel - isle.vel).LengthSquared() > thresh)
					{
						stream.write_bool(true);
						stream.write_Vec2f(isle.vel);
						isle.net_vel = isle.vel;
					}
					else stream.write_bool(false);
					
					if (Maths::Abs(isle.net_angle - isle.angle) > thresh)
					{
						stream.write_bool(true);
						stream.write_f32(isle.angle);
						isle.net_angle = isle.angle;
					}
					else stream.write_bool(false);

					if (Maths::Abs(isle.net_angle_vel - isle.angle_vel) > thresh)
					{
						stream.write_bool(true);
						stream.write_f32(isle.angle_vel);
						isle.net_angle_vel = isle.angle_vel;
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
	
	warn("islands not found on serialize");
	return false;
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params)
{
	if (isServer()) return;

	if (cmd == this.getCommandID("islands sync"))
	{
		Island[]@ islands;
		if (this.get("islands", @islands))
		{
			islands.clear();
			const u16 count = params.read_u16();
			for (uint i = 0; i < count; ++i)
			{
				Island isle;
				if (!params.saferead_Vec2f(isle.pos))
				{
					warn("islands sync: isle.pos not found");
					return;
				}
				u16 ownerID = params.read_u16();
				CPlayer@ owner = ownerID != 0 ? getPlayerByNetworkId(ownerID) : null;
				isle.owner = owner !is null ? owner.getUsername() : "";
				u16 centerBlockID = params.read_u16();
				@isle.centerBlock = centerBlockID != 0 ? getBlobByNetworkID(centerBlockID) : null;
				isle.vel = params.read_Vec2f();
				isle.angle = params.read_f32();
				isle.angle_vel = params.read_f32();
				isle.mass = params.read_f32();
				isle.isMothership = params.read_bool();
				isle.isStation = params.read_bool();
				isle.isMiniStation = params.read_bool();
				isle.isSecondaryCore = params.read_bool();
				if (isle.centerBlock !is null)
				{
					isle.initialized = true;
					if (isle.vel.LengthSquared() > 0.01f)//try to use local values to smoother sync
					{
						isle.pos = isle.centerBlock.getPosition();
						isle.angle = isle.centerBlock.getAngleDegrees();
					}
				}
				isle.old_pos = isle.pos;
				isle.old_angle = isle.angle;
				
				const u16 blocks_count = params.read_u16();
				for (uint q = 0; q < blocks_count; ++q)
				{
					u16 netid;
					if (!params.saferead_netid(netid))
					{
						warn("islands sync: netid not found");
						return;
					}
					CBlob@ b = getBlobByNetworkID(netid);
					Vec2f pos = params.read_Vec2f();
					f32 angle = params.read_f32();
					if (b !is null)
					{
						IslandBlock isle_block;
						isle_block.blobID = netid;
						isle_block.offset = pos;
						isle_block.angle_offset = angle;
						isle.blocks.push_back(isle_block);	
	    				b.getShape().getVars().customData = i+1; // color		
							// safety on desync
							b.SetVisible(true);
						    CSprite@ sprite = b.getSprite();
	    					sprite.asLayer().SetColor(color_white);
	    					sprite.asLayer().setRenderStyle(RenderStyle::normal);
					}
					else
						warn(" Blob not found when creating island, id = " + netid);
				}
				islands.push_back(isle);
			}

			UpdateIslands(this, false);
		}
		else
		{
			warn("Islands not found on sync");
			return;
		}
	}
	else if (cmd == this.getCommandID("islands update"))
	{
		Island[]@ islands;
		if (this.get("islands", @islands))
		{
			u16 count;
			if (!params.saferead_u16(count))
			{
				warn("islands update: count not found");
				return;
			}
			if (count != islands.length)
			{
				warn("Update received before island sync " + count + " != " + islands.length);
				return;
			}
			for (uint i = 0; i < count; ++i)
			{
				if (params.read_bool())
				{
					Island @isle = islands[i];
					u16 ownerID = params.read_u16();
					CPlayer@ owner = ownerID != 0 ? getPlayerByNetworkId(ownerID) : null;
					isle.owner = owner !is null ? owner.getUsername() : "";
					if (params.read_bool())
					{
						Vec2f dDelta = params.read_Vec2f() - isle.pos;
						if ( dDelta.LengthSquared() < 512 )//8 blocks threshold
							isle.pos = isle.pos + dDelta/UPDATE_DELTA_SMOOTHNESS;
						else
							isle.pos += dDelta; 
					}
					if (params.read_bool())
					{
						isle.vel = params.read_Vec2f()/VEL_DAMPING;
					}
					if (params.read_bool())
					{
						f32 aDelta =  params.read_f32() - isle.angle;
						if (aDelta > 180)	aDelta -= 360;
						if (aDelta < -180)	aDelta += 360;
						isle.angle = isle.angle + aDelta/UPDATE_DELTA_SMOOTHNESS;
						while (isle.angle < 0.0f)	isle.angle += 360.0f;
						while (isle.angle > 360.0f)	isle.angle -= 360.0f;
					}
					if (params.read_bool())
					{
						isle.angle_vel = params.read_f32()/ANGLE_VEL_DAMPING;
					}
				}
			}
			//no need to UpdateIslands()
		}
		else
		{
			warn("Islands not found on update");
			return;
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (!player.isMyPlayer())
		Synchronize(this, true, player); // will set old values
}

bool isIslandChanged(Island@ isle)
{
	const f32 thresh = 0.01f;
	return ((isle.pos - isle.old_pos).LengthSquared() > thresh || Maths::Abs(isle.angle - isle.old_angle) > thresh);
}

bool candy = false;
bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player )
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
						UPDATE_DELTA_SMOOTHNESS = Maths::Max( 1.0f, parseFloat( tokens[1] ) );
						client_AddToChat("Delta smoothness set to " + UPDATE_DELTA_SMOOTHNESS );
					}
					else
						client_AddToChat("Delta smoothness: " + UPDATE_DELTA_SMOOTHNESS );
				}
				return false;
			}
		}
	}
	
	return true;
}

void onRender(CRules@ this)
{
	//draw island colors & block ids
	
	if (g_debug == 1 || candy)
	{
		CCamera@ camera = getCamera();
		if (camera is null) return;
		f32 camRotation = camera.getRotation();
		Island[]@ islands;
		if (this.get("islands", @islands))
		{
			for (uint i = 0; i < islands.length; ++i)
			{
				Island @isle = islands[i];
				if (isle.centerBlock !is null)
				{
					Vec2f cbPos = getDriver().getScreenPosFromWorldPos(isle.centerBlock.getPosition());
					Vec2f iVel = isle.vel * 20;
					iVel.RotateBy(-camRotation);					
					GUI::DrawArrow2D(cbPos, cbPos + iVel, SColor(175, 0, 200, 0));
					//GUI::DrawText("" + isle.vel.Length(), cbPos, SColor( 255,255,255,255));
				}
					
				for (uint b_iter = 0; b_iter < isle.blocks.length; ++b_iter)
				{
					IslandBlock@ isle_block = isle.blocks[b_iter];
					CBlob@ b = getBlobByNetworkID(isle_block.blobID);
					if (b !is null)
					{
						int c = b.getShape().getVars().customData;
						GUI::DrawRectangle(getDriver().getScreenPosFromWorldPos(b.getPosition() - Vec2f(4, 4).RotateBy(camRotation)), 
										   getDriver().getScreenPosFromWorldPos(b.getPosition() + Vec2f(4, 4).RotateBy(camRotation)), SColor(100, c*50, -c*90, 93*c));
						GUI::DrawText("" + isle_block.blobID, getDriver().getScreenPosFromWorldPos(b.getPosition()), SColor(255,255,255,255));
					}
				}
			}
		}
	}
}
