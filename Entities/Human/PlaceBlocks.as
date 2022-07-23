#include "ShipsCommon.as";
#include "AccurateSoundPlay.as";
#include "BlockCosts.as";

const f32 rotate_speed = 30.0f;
const f32 max_build_distance = 32.0f;
const u32 placement_time = 22;
u8 crewCantPlaceCounter = 0;

void onInit(CBlob@ this)
{
	u16[] blocks;
	this.set("blocks", blocks);
	this.set_f32("blocks_angle", 0.0f);
	this.set_f32("target_angle", 0.0f);

	this.addCommandID("place");
}

CBlob@ getReferenceBlock(CBlob@ this, Ship@ ship, CBlob@ shipBlob) //find specific origin blocks connected to a ship
{
	const u8 teamNum = this.getTeamNum();
	CBlob@[] references;

	if (ship.isMothership)
		return getMothership(teamNum);
	if (ship.isSecondaryCore)
		getBlobsByTag("secondaryCore", @references);
	else if (ship.isStation)
		getBlobsByTag("station", @references);
	else getBlobsByTag("seat", @references);
	
	const u16 refLength = references.length;
	for (u16 i = 0; i < refLength; i++)
	{
		CBlob@ ref = references[i];
		if (ref.getTeamNum() == teamNum && ref.getShape().getVars().customData == shipBlob.getShape().getVars().customData)
			return ref;
	}
	
	return ship.centerBlock;
}

void onTick(CBlob@ this)
{
	u16[] blocks;
	if (!this.get("blocks", blocks) || blocks.size() <= 0)
		return;
	
	Vec2f pos = this.getPosition();
	const u8 blocksLength = blocks.length;
	const s32 overlappingShipID = this.get_s32("shipID");
	Ship@ ship = overlappingShipID > 0 ? getShipSet().getShip(overlappingShipID) : null;
	if (ship !is null && ship.centerBlock !is null)
	{
		CBlob@ shipBlob = getBlobByNetworkID(this.get_u16("shipBlobID"));
		if (shipBlob is null)
		{
			warn("PlaceBlocks: shipBlob not found");
			return;
		}
		
		CBlob@ refBlock = getReferenceBlock(this, ship, shipBlob);
		if (refBlock is null)
		{
			warn("PlaceBlocks: centerblock not found");
			return;
		}
		
		f32 blocks_angle = this.get_f32("blocks_angle"); //next step angle
		f32 target_angle = this.get_f32("target_angle"); //final angle (after manual rotation)
		Vec2f aimPos = this.getAimPos();

		PositionBlocks(blocks, pos, aimPos, blocks_angle, refBlock, shipBlob);

		CPlayer@ player = this.getPlayer();
		if (player !is null && player.isMyPlayer() && !this.get_bool("justMenuClicked")) 
		{
			//checks for canPlace
			const bool skipCoreCheck = !getRules().isWarmup() || (ship.isMothership && (ship.owner.isEmpty() || ship.owner == "*" || ship.owner == player.getUsername()));
			const bool overlappingShip = blocksOverlappingShip(blocks);
			bool cLinked = false;
			bool onRock = false;
			bool not_ready = (getGameTime() - this.get_u32("placedTime")) <= placement_time; // dont show block if we are not ready to build yet
			for (u8 i = 0; i < blocksLength; ++i)
			{
				CBlob@ block = getBlobByNetworkID(blocks[i]);
				if (block is null) continue;
				
				CMap@ map = getMap();
				Tile bTile = map.getTile(block.getPosition());
				if (map.isTileSolid(bTile))
					onRock = true;
				
				if (overlappingShip || onRock || not_ready)
				{
					SetDisplay(block, SColor(255, 255, 0, 0), RenderStyle::additive);
					continue;
				}
				
				if (skipCoreCheck || block.hasTag("coupling") || block.hasTag("repulsor"))
					continue;
					
				if (!cLinked)
				{
					CBlob@ core = getMothership(this.getTeamNum()); //could get the core properly based on adjacent blocks
					if (core !is null)
					{
						u16[] checked, unchecked;
						cLinked = shipLinked(block, core, checked, unchecked, false);
					}
				}
				 
				if (cLinked)
					SetDisplay(block, SColor(255, 255, 0, 0), RenderStyle::additive);
			}
			
			//can't Place heltips
			const bool crewCantPlace = !overlappingShip && cLinked;
			if (crewCantPlace)
				crewCantPlaceCounter++;
			else
				crewCantPlaceCounter = 0;

			this.set_bool("blockPlacementWarn", crewCantPlace && crewCantPlaceCounter > 15);
			
			// place
			if (this.isKeyPressed(key_action1) && !getHUD().hasMenus() && !getHUD().hasButtons())
			{
				const u32 gameTime = getGameTime();
				if (gameTime - this.get_u32("placedTime") > placement_time)
				{
					if (target_angle == blocks_angle && !overlappingShip && !cLinked && !onRock)
					{
						Vec2f shipPos = refBlock.getPosition();
						
						CBitStream params;
						params.write_netid(refBlock.getNetworkID());
						params.write_netid(shipBlob.getNetworkID());
						params.write_Vec2f(pos - shipPos);
						params.write_Vec2f(aimPos - shipPos);
						params.write_f32(target_angle);
						params.write_f32(refBlock.getAngleDegrees());
						this.SendCommand(this.getCommandID("place"), params);
						this.set_u32("placedTime", gameTime);
					}
					else
					{
						this.getSprite().PlaySound("Denied.ogg");
						this.set_u32("placedTime", gameTime - 10);
					}
				}
			}

			// rotate
			if (this.isKeyJustPressed(key_action3))
			{
				target_angle += 90.0f;
				if (target_angle > 360.0f)
				{
					target_angle -= 360.0f;
					blocks_angle -= 360.0f;
				}
				this.set_f32("target_angle", target_angle);
				this.Sync("target_angle", false); //-1491678232 HASH
			}
		}

		blocks_angle += rotate_speed;
		if (blocks_angle > target_angle)
			blocks_angle = target_angle;        
		this.set_f32("blocks_angle", blocks_angle);
	}
	else
	{
		// cant place in water
		for (u8 i = 0; i < blocksLength; ++i)
		{
			CBlob@ block = getBlobByNetworkID(blocks[i]);
			if (block is null) continue;
			
			SetDisplay(block, SColor(255, 255, 0, 0), RenderStyle::light, -10.0f);
		}
	}
}

void PositionBlocks(u16[] blocks, Vec2f&in pos, Vec2f&in aimPos, const f32&in blocks_angle, CBlob@ refBlock, CBlob@ shipBlob)
{
	Vec2f ship_pos = refBlock.getPosition();
	const f32 angle = refBlock.getAngleDegrees();
	f32 refBAngle = shipBlob.getAngleDegrees(); //reference block angle
	//current ship angle as point of reference
	while (refBAngle > angle + 45) refBAngle -= 90.0f;
	while (refBAngle < angle - 45) refBAngle += 90.0f;
	
	//add offset (based on the refBlock) of block we're standing on
	Vec2f refBOffset = shipBlob.getPosition() - ship_pos;
	refBOffset.RotateBy(-refBAngle); refBOffset.x %= 8.0f; refBOffset.y %= 8.0f; refBOffset.RotateBy(refBAngle);
	ship_pos += refBOffset;
	
	Vec2f mouseAim = aimPos - pos;
	const f32 maxDistance = Maths::Min(mouseAim.Normalize(), max_build_distance); //set the maximum distance we can place at
	aimPos = pos + mouseAim * maxDistance; //position of the 'buildblock' pointer
	Vec2f shipAim = aimPos - ship_pos; //ship to 'buildblock' pointer
	shipAim.RotateBy(-refBAngle); shipAim = SnapToGrid(shipAim); shipAim.RotateBy(refBAngle);
	Vec2f cursor_pos = ship_pos + shipAim; //position of snapped buildblock
	
	//rotate and position blocks
	const u8 blocksLength = blocks.length;
	for (u8 i = 0; i < blocksLength; ++i)
	{
		CBlob@ block = getBlobByNetworkID(blocks[i]);
		if (block is null) continue;
		
		Vec2f offset = block.get_Vec2f("offset");
		offset.RotateBy(blocks_angle + refBAngle);

		block.setPosition(cursor_pos + offset); //align to ship grid
		block.setAngleDegrees((refBAngle + blocks_angle + (block.hasTag("engine") ? 90.0f : 0.0f)) % 360.0f); //set angle: reference angle + rotation angle

		SetDisplay(block, color_white, RenderStyle::additive, 315.0f);
	}
}

Vec2f SnapToGrid(Vec2f&in pos) //determines the grid of blocks
{
	pos.x = Maths::Floor(pos.x / 8.0f + 0.5f);
	pos.y = Maths::Floor(pos.y / 8.0f + 0.5f);
	pos *= 8;
	return pos;
}

const bool blocksOverlappingShip(u16[] blocks)
{
	const u8 blocksLength = blocks.length;
	for (u8 i = 0; i < blocksLength; ++i)
	{
		CBlob@ block = getBlobByNetworkID(blocks[i]);
		if (block is null) continue;
		
		CBlob@[] overlapping; //we use radius since getOverlapping has a delay when blob is created
		if (getMap().getBlobsInRadius(block.getPosition(), 8.0f, @overlapping))
		{
			const u8 overlappingLength = overlapping.length;
			for (u8 q = 0; q < overlappingLength; q++)
			{
				CBlob@ b = overlapping[q];
				if (b.getShape().getVars().customData > 0)
				{
					if ((b.getPosition() - block.getPosition()).getLength() < block.getRadius() * 0.4f)
						return true;
				}
			}
		}
	}
	return false; 
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("place"))
	{
		CBlob@ refBlock = getBlobByNetworkID(params.read_netid());
		CBlob@ shipBlob = getBlobByNetworkID(params.read_netid());
		if (refBlock is null || shipBlob is null)
		{
			warn("place cmd: centerBlock not found");
			return;
		}

		Vec2f pos_offset = params.read_Vec2f();
		Vec2f aimPos_offset = params.read_Vec2f();
		const f32 target_angle = params.read_f32();
		const f32 ship_angle = params.read_f32();
		
		CRules@ rules = getRules();
		ShipDictionary@ ShipSet = getShipSet(rules);
		Ship@ ship = ShipSet.getShip(refBlock.getShape().getVars().customData);
		if (ship is null)
		{
			warn("place cmd: ship not found");
			return;
		}
		
		if (ship.centerBlock is null)
		{
			warn("place cmd: ship centerBlock not found");
			return;
		}
		
		u16[] blocks;
		if (this.get("blocks", blocks) && blocks.size() > 0)
		{
			Vec2f shipPos = refBlock.getPosition();
			const f32 shipAngle = ship.centerBlock.getAngleDegrees();
			const f32 angleDelta = refBlock.getAngleDegrees() - ship_angle; //to account for ship angle lag
			const u8 blocksLength = blocks.length;
			
			if (isServer())
			{
				CBlob@[] blob_blocks;
				for (u8 i = 0; i < blocksLength; ++i)
				{
					CBlob@ b = getBlobByNetworkID(blocks[i]);
					if (b !is null) blob_blocks.push_back(b);
				}
				
				rules.push("dirtyBlocks", blob_blocks);
				PositionBlocks(blocks, shipPos + pos_offset.RotateBy(angleDelta), shipPos + aimPos_offset.RotateBy(angleDelta), target_angle, refBlock, shipBlob);
			}

			const int iColor = refBlock.getShape().getVars().customData;
			for (u8 i = 0; i < blocksLength; ++i)
			{
				CBlob@ b = getBlobByNetworkID(blocks[i]);
				if (b is null)
				{
					if (sv_test) warn("place cmd: blob not found");
					continue;
				}
				
				b.set_netid("ownerID", 0); //so it wont add to owner blocks
				
				const f32 z = b.hasTag("platform") ? 309.0f : (b.hasTag("weapon") ? 311.0f : 310.0f);
				SetDisplay(b, color_white, RenderStyle::normal, z);
				
				if (!isServer()) //add it locally till a sync
				{
					ShipBlock ship_block;
					ship_block.blobID = b.getNetworkID();
					ship_block.offset = b.getPosition() - ship.centerBlock.getPosition();
					ship_block.offset.RotateBy(-shipAngle);
					ship_block.angle_offset = b.getAngleDegrees() - shipAngle;
					b.getShape().getVars().customData = iColor;
					ship.blocks.push_back(ship_block);
				}
				else
					b.getShape().getVars().customData = 0; // push on ship
				
				b.set_u32("placedTime", getGameTime());
			}
		}
		else
		{
			//can happen when placing and returning blocks at same time
			if (sv_test) warn("place cmd: no blocks");
			return;
		}
		
		this.clear("blocks"); //releases the blocks (they are placed)
		directionalSoundPlay("build_ladder.ogg", this.getPosition());
		
		//Grab another block
		if (this.isMyPlayer() && !this.isAttached())
		{
			CBlob@ core = getMothership(this.getTeamNum());
			if (core !is null && !core.hasTag("critical"))
			{
				const s32 overlappingShipID = this.get_s32("shipID");
				Ship@ pShip = overlappingShipID > 0 ? ShipSet.getShip(overlappingShipID) : null;
				if (pShip !is null && pShip.centerBlock !is null && ((pShip.id == core.getShape().getVars().customData) 
					|| ((pShip.isStation || pShip.isSecondaryCore) && pShip.centerBlock.getTeamNum() == this.getTeamNum())))
				{
					this.set_bool("getting block", true);
					this.Sync("getting block", false);
				}
			}
		}
	}
}

void SetDisplay(CBlob@ blob, const SColor&in color, RenderStyle::Style&in style, const f32&in Z = -10000)
{
	CSprite@ sprite = blob.getSprite();
	sprite.asLayer().SetColor(color);
	sprite.asLayer().setRenderStyle(style);
	if (Z > -10000)
	{
		sprite.SetZ(Z);
	}
}
