#include "ShipsCommon.as";
#include "AccurateSoundPlay.as";
#include "BlockHooks.as";
#include "BlockCosts.as";

const f32 rotate_speed = 30.0f;
const f32 max_build_distance = 32.0f;
const u32 placement_time = 22;
u8 crewCantPlaceCounter = 0;

void onInit(CBlob@ this)
{
    CBlob@[] blocks;
    this.set("blocks", blocks);
    this.set_f32("blocks_angle", 0.0f);
    this.set_f32("target_angle", 0.0f);

    this.addCommandID("place");
}

CBlob@ getReferenceBlock(CBlob@ this, Ship@ ship) //find specific origin blocks connected to an ship
{
	if (ship !is null)
	{
		CBlob@[] references;

		if (ship.isMothership)
			return getMothership(this.getTeamNum());
		else if (ship.isSecondaryCore)
			getBlobsByTag("secondaryCore", @references);
		else if (ship.isStation)
			getBlobsByTag("station", @references);
		else getBlobsByTag("seat", @references);
		
		const u16 refLength = references.length;
		for (u16 i = 0; i < refLength; i++)
		{
			CBlob@ ref = references[i];
			if (ref.getTeamNum() == this.getTeamNum() && 
				ref.getShape().getVars().customData == getShipBlob(this).getShape().getVars().customData)
				return ref;
		}

		if (ship.centerBlock !is null) 
			return ship.centerBlock;
	}
	return null;
}

void onTick(CBlob@ this)
{
    CBlob@[]@ blocks;
    if (this.get("blocks", @blocks) && blocks.size() > 0)
    {
		Vec2f pos = this.getPosition();
		const u8 blocksLength = blocks.length;
	
        Ship@ ship = getShip(this);
		if (ship !is null && ship.centerBlock !is null)
        {
			CBlob@ centerBlock = getReferenceBlock(this, ship);
			Vec2f shipPos = centerBlock.getPosition();
			f32 blocks_angle = this.get_f32("blocks_angle");//next step angle
			f32 target_angle = this.get_f32("target_angle");//final angle (after manual rotation)
			Vec2f aimPos = this.getAimPos();
			
			CBlob@ refBlob = getShipBlob(this);
            if (refBlob is null)
			{
				warn("PlaceBlocks: refBlob not found");
                return;
            }

			//if (isClient())
				PositionBlocks(@blocks, pos, aimPos, blocks_angle, centerBlock, refBlob);

			CPlayer@ player = this.getPlayer();
            if (player !is null && player.isMyPlayer() && !this.get_bool("justMenuClicked")) 
            {
				//checks for canPlace
				bool skipCoreCheck = !getRules().isWarmup() || (ship.isMothership && (ship.owner == "" || ship.owner == "*" || ship.owner == player.getUsername()));
				bool cLinked = false;
				bool onRock = false;
                const bool overlappingShip = blocksOverlappingShip(@blocks);
				for (u8 i = 0; i < blocksLength; ++i)
				{
					CBlob@ block = blocks[i];
					CMap@ map = getMap();
					Tile bTile = map.getTile(block.getPosition());
					if (map.isTileSolid(bTile))
						onRock = true;
					
					if (overlappingShip || onRock)
					{
						SetDisplay(block, SColor(255, 255, 0, 0), RenderStyle::additive);
						continue;
					}
					
					if (skipCoreCheck || blocks[i].hasTag("coupling") || block.hasTag("repulsor"))
						continue;
						
					if (!cLinked)
					{
						CBlob@ core = getMothership(this.getTeamNum());//could get the core properly based on adjacent blocks
						if (core !is null)
						{
							u16[] checked, unchecked;
							cLinked = coreLinkedPathed(block, core, checked, unchecked, false);
						}
					}
					 
					if (cLinked)
						SetDisplay(block, SColor(255, 255, 0, 0), RenderStyle::additive);
				}
				
				//can't Place heltips
				bool crewCantPlace = !overlappingShip && cLinked;
				if (crewCantPlace)
					crewCantPlaceCounter++;
				else
					crewCantPlaceCounter = 0;

				this.set_bool("blockPlacementWarn", crewCantPlace && crewCantPlaceCounter > 15);
				
                // place
                if (this.isKeyPressed(key_action1) && !getHUD().hasMenus() && !getHUD().hasButtons())
                {
					if (getGameTime() - this.get_u32("placedTime") > placement_time)
					{
						if (target_angle == blocks_angle && !overlappingShip && !cLinked && !onRock)
						{
							CBitStream params;
							params.write_netid(centerBlock.getNetworkID());
							params.write_netid(refBlob.getNetworkID());
							params.write_Vec2f(pos - shipPos);
							params.write_Vec2f(aimPos - shipPos);
							params.write_f32(target_angle);
							params.write_f32(centerBlock.getAngleDegrees());
							this.SendCommand(this.getCommandID("place"), params);
							this.set_u32("placedTime", getGameTime());
						}
						else
						{
							this.getSprite().PlaySound("Denied.ogg");
							this.set_u32("placedTime", getGameTime() - 10);
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
                CBlob@ block = blocks[i];
                SetDisplay(block, SColor(255, 255, 0, 0), RenderStyle::light, -10.0f);
            }
        }
    }
}

void PositionBlocks(CBlob@[]@ blocks, Vec2f pos, Vec2f aimPos, const f32 blocks_angle, CBlob@ centerBlock, CBlob@ refBlock)
{
    if (centerBlock is null)
	{
        warn("PositionBlocks: centerblock not found");
        return;
    }
	
	Vec2f ship_pos = centerBlock.getPosition();
    f32 angle = centerBlock.getAngleDegrees();
	f32 refBAngle = refBlock.getAngleDegrees();//reference block angle
	//current ship angle as point of reference
	while (refBAngle > angle + 45) refBAngle -= 90.0f;
	while (refBAngle < angle - 45) refBAngle += 90.0f;
	
	//get offset (based on the centerblock) of block we're standing on
	Vec2f refBOffset = refBlock.getPosition() - ship_pos;
	refBOffset.RotateBy(-refBAngle);
	refBOffset.x = refBOffset.x % 8.0f;
	refBOffset.y = refBOffset.y % 8.0f;
	//not really necessary
	if (refBOffset.x > 4.0f) refBOffset.x -= 8.0f; else if (refBOffset.x < -4.0f) refBOffset.x += 8.0f;
	if (refBOffset.y > 4.0f) refBOffset.y -= 8.0f; else if (refBOffset.y < -4.0f) refBOffset.y += 8.0f;
	refBOffset.RotateBy(refBAngle);
	
	ship_pos += refBOffset;
	Vec2f mouseAim = aimPos - pos;
	f32 mouseDist = Maths::Min(mouseAim.Normalize(), max_build_distance);
	aimPos = pos + mouseAim * mouseDist;//position of the 'buildblock' pointer
	Vec2f shipAim = aimPos - ship_pos;//ship to 'buildblock' pointer
	shipAim.RotateBy(-refBAngle); shipAim = SnapToGrid(shipAim); shipAim.RotateBy(refBAngle);
	Vec2f cursor_pos = ship_pos + shipAim;//position of snapped buildblock
	
	//rotate and position blocks
	const u8 blocksLength = blocks.length;
	for (u8 i = 0; i < blocksLength; ++i)
	{
		CBlob@ block = blocks[i];
		Vec2f offset = block.get_Vec2f("offset");
		offset.RotateBy(blocks_angle);
		offset.RotateBy(refBAngle);
  
		block.setPosition(cursor_pos + offset);//align to ship grid
		block.setAngleDegrees((refBAngle + blocks_angle + (block.hasTag("engine") ? 90.0f : 0.0f)) % 360.0f);//set angle: reference angle + rotation angle

		SetDisplay(block, color_white, RenderStyle::additive, 315.0f);
	}
}

Vec2f SnapToGrid(Vec2f pos) //determines the grid of blocks
{
    pos.x = Maths::Round(pos.x / 8.0f);
    pos.y = Maths::Round(pos.y / 8.0f);
    pos.x *= 8;
    pos.y *= 8;
    return pos;
}

bool blocksOverlappingShip(CBlob@[]@ blocks)
{
	const u8 blocksLength = blocks.length;
    for (u8 i = 0; i < blocksLength; ++i)
    {
        CBlob@ block = blocks[i];
		
		CBlob@[] overlapping; //we use radius since getOverlapping has a delay when blob is created
		if (getMap().getBlobsInRadius(block.getPosition(), 8.0f, @overlapping))
		{
			const u8 overlappingLength = overlapping.length;
			for (u8 q = 0; q < overlappingLength; q++)
			{
				CBlob@ b = overlapping[q];
				if (b.getShape().getVars().customData > 0)
				{
					if ((b.getPosition() - block.getPosition()).getLength() < block.getRadius()*0.4f)
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
        CBlob@ centerBlock = getBlobByNetworkID(params.read_netid());
        CBlob@ refBlock = getBlobByNetworkID(params.read_netid());
        if (centerBlock is null || refBlock is null)
        {
            warn("place cmd: centerBlock not found");
            return;
        }

        Vec2f pos_offset = params.read_Vec2f();
        Vec2f aimPos_offset = params.read_Vec2f();
        const f32 target_angle = params.read_f32();
        const f32 ship_angle = params.read_f32();

        Ship@ ship = getShip(centerBlock.getShape().getVars().customData);
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
		
		Vec2f shipPos = centerBlock.getPosition();
		f32 shipAngle = ship.centerBlock.getAngleDegrees();
		f32 angleDelta = centerBlock.getAngleDegrees() - ship_angle;//to account for ship angle lag
		
        CBlob@[]@ blocks;
        if (this.get("blocks", @blocks) && blocks.size() > 0)                 
        {
			if (isServer())
			{
				getRules().push("dirtyBlocks", blocks);
				PositionBlocks(@blocks, shipPos + pos_offset.RotateBy(angleDelta), shipPos + aimPos_offset.RotateBy(angleDelta), target_angle, centerBlock, refBlock);
			}

			int iColor = centerBlock.getShape().getVars().customData;
			const u8 blocksLength = blocks.length;
			for (u8 i = 0; i < blocksLength; ++i)
			{
				CBlob@ b = blocks[i];
				if (b !is null)
				{
					b.set_netid("ownerID", 0);//so it wont add to owner blocks
					f32 z = 310.0f;
					if (b.hasTag("platform")) z = 309.0f;//platforms
					else if (b.hasTag("weapon")) z = 311.0f;//weaps
					SetDisplay(b, color_white, RenderStyle::normal, z);
					if (!isServer())//add it locally till a sync
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

					BlockHooks@ blockHooks;
					b.get("BlockHooks", @blockHooks);
					if (blockHooks !is null)
						blockHooks.update("onBlockPlaced", @b); //Activate hook onBlockPlaced for all blobs that have it
					
					b.set_u32("placedTime", getGameTime());
				}
				else
				{
					warn("place cmd: blob not found");
				}
			}
        }
        else
        {
			//can happen when placing and returning blocks at same time
            warn("place cmd: no blocks");
            return;
        }
		
		blocks.clear();//releases the blocks (they are placed)
		directionalSoundPlay("build_ladder.ogg", this.getPosition());
		
		//Grab another block
		if (this.isMyPlayer() && !this.isAttached())
		{
			CBlob@ core = getMothership(this.getTeamNum());
			if (core !is null && !core.hasTag("critical"))
			{
				Ship@ pShip = getShip(this);
				bool canShop = pShip !is null && pShip.centerBlock !is null 
								&& ((pShip.centerBlock.getShape().getVars().customData == core.getShape().getVars().customData) 
								|| ((pShip.isStation || pShip.isSecondaryCore) && pShip.centerBlock.getTeamNum() == this.getTeamNum()));
				if (canShop)
				{
					this.set_bool("getting block", true);
					this.Sync("getting block", false);
				}
			}
		}
    }
}

void SetDisplay(CBlob@ blob, SColor color, RenderStyle::Style style, f32 Z = -10000)
{
    CSprite@ sprite = blob.getSprite();
    sprite.asLayer().SetColor(color);
    sprite.asLayer().setRenderStyle(style);
    if (Z > -10000)
	{
        sprite.SetZ(Z);
    }
}