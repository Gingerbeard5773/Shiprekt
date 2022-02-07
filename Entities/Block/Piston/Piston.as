//Gingerbeard @ 1/11/2022

#include "AccurateSoundPlay.as";
#include "IslandsCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("piston");
    this.Tag("solid");
	
	this.set_f32("weight", 0.85f);
	
	this.set_bool("toggled", false);
	
	CBlob@[] pushblocks; //blocks that the piston can push
    this.set("pushBlocks", pushblocks);

	this.addCommandID("togglepiston");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getShape().getVars().customData <= 0)//mycolour
        return;

	//only owners can activate
    if (this.getDistanceTo(caller) < 8
		&& !getMap().isBlobWithTagInRadius("hasSeat", caller.getPosition(), 0.0f)
		&& caller.getPlayer().getUsername() == this.get_string("playerOwner"))
	{
		CButton@ button = caller.CreateGenericButton(this.get_bool("toggled") ? 1 : 8, Vec2f(), this, this.getCommandID("togglepiston"), this.get_bool("toggled") ? "Retract" : "Extend");
		if (button !is null) button.radius = 3.3f; //engine fix
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("togglepiston"))
    {	
		CSprite@ sprite = this.getSprite();
		CShape@ shape = this.getShape();
		
		Vec2f aimVector = Vec2f(0, -1).RotateBy(this.getAngleDegrees());
		
		CBlob@[] blobs; //get block directly infront of piston
		getMap().getBlobsAtPosition(this.getPosition() + Vec2f(5 + (this.get_bool("toggled") ? 10 : 0), 0).RotateBy(-aimVector.Angle()), @blobs);
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			if (blob is this || !blob.hasTag("block") || blob.getShape().getVars().customData == 0) continue;
			
			this.push("pushBlocks", @blob); //add block to piston's pushblocks
			AddLinked(blob, this, getGameTime()); //start search loop
		}
		
		CBlob@[]@ pushBlocks;
		this.get("pushBlocks", @pushBlocks);
		//print(pushBlocks.length+"");
		
		if (pushBlocks.length > 0 && !this.get_bool("locked"))
		{
			CBlob@[] frontblobs;
			if (this.get_bool("toggled")) //make sure there is no block touching front of the piston while toggled on
			{
				getMap().getBlobsAtPosition(this.getPosition() + Vec2f(5, 0).RotateBy(-aimVector.Angle()), @frontblobs);
				for (int i = 0; i < frontblobs.length; i++)
				{
					if (!frontblobs[i].hasTag("block") || frontblobs[i].getShape().getVars().customData == 0 || frontblobs[i] is this)
						frontblobs.erase(i);
				}
			}
			
			//move blocks!
			if (frontblobs.length <= 0)
			{
				for (int i = 0; i < pushBlocks.length; i++)
				{
					CBlob@ blob = pushBlocks[i];
					
					Island@ island = getIsland(blob.getShape().getVars().customData);
					if (island !is null)
					{
						for (uint i = 0; i < island.blocks.length; ++i)
						{
							IslandBlock@ isle_block = island.blocks[i];
							CBlob@ block = getBlobByNetworkID(isle_block.blobID);
							if (block is null || block !is blob) continue;
							
							Vec2f movePos = Vec2f(0, -8 * (this.get_bool("toggled") ? -1 : 1)).RotateBy(this.getAngleDegrees() - island.angle);
							isle_block.offset += movePos;
						}
					}
				}
			}
		}
		
		if (!this.get_bool("locked"))
		{
			if (!this.get_bool("toggled"))
			{
				Vec2f[] points = {Vec2f(-4, 4), Vec2f(4, 4), Vec2f(4, -12), Vec2f(-4, -12)}; //enlarge shape to include piston arm
				shape.SetShape(points);
				shape.getConsts().radius = 5.6f; //counter shape radius (engine adds onto it but we dont want that)

				directionalSoundPlay("DispenserFire.ogg", this.getPosition());
				sprite.SetFrame(1);
				this.set_bool("toggled", true);
			}
			else
			{
				Vec2f[] points = {Vec2f(-4, -4), Vec2f(4, -4), Vec2f(4, 4), Vec2f(-4, 4)}; //set shape back to normal
				shape.SetShape(points);
				
				directionalSoundPlay("LoadingTick2.ogg", this.getPosition());
				sprite.SetFrame(0);
				this.set_bool("toggled", false);
			}
		}
		else
			directionalSoundPlay("dry_hit.ogg", this.getPosition());
		
		this.clear("pushBlocks");
		this.set_bool("locked", false);
    }
}

void AddLinked(CBlob@ this, CBlob@ piston, u16 checkToken)
{
	Vec2f aimVector = Vec2f(0, -1).RotateBy(this.getAngleDegrees());
	CMap@ map = getMap();
	
	CBlob@[] blobs;
	//add blobs from each side of this block
	if (this.hasTag("piston") && this.get_bool("toggled")) //account for piston 'toggled' distance
		map.getBlobsAtPosition(this.getPosition() + Vec2f(14, 0).RotateBy(-aimVector.Angle()), @blobs); //front farther
	else
		map.getBlobsAtPosition(this.getPosition() + Vec2f(5, 0).RotateBy(-aimVector.Angle()), @blobs); //front
		
	map.getBlobsAtPosition(this.getPosition() + Vec2f(0, 5).RotateBy(-aimVector.Angle()), @blobs); //left
	map.getBlobsAtPosition(this.getPosition() + Vec2f(-5, 0).RotateBy(-aimVector.Angle()), @blobs); //right
	map.getBlobsAtPosition(this.getPosition() + Vec2f(0, -5).RotateBy(-aimVector.Angle()), @blobs); //back
	
	Island@ island = getIsland(this.getShape().getVars().customData);
	if (island !is null && island.centerBlock !is null)
	{
		this.set_u16("pistonToken", checkToken);
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			
			if (blob.getShape().getVars().customData != piston.getShape().getVars().customData) //don't pass
				continue;
				
			if (blob is getIslandCenter(island))
			{
				//don't move any blocks (piston is locked)
				piston.clear("pushBlocks");
				piston.set_bool("locked", true);
				return;
			}
			
			if (blob is piston || !blob.hasTag("block")) //don't pass
				continue;
			
			if (blob.getShape().getVars().customData > 0 && blob.get_u16("pistonToken") != checkToken)
			{
				piston.push("pushBlocks", @blob); //add blob block to piston's pushblocks
				AddLinked(blob, piston, checkToken); //repeat until we find the centerBlock
			}
		}
	}
}

CBlob@ getIslandCenter(Island@ island)
{
	//use mothership core if present, otherwise use the centerblock
	if (island.isMothership)
		return getMothership(island.centerBlock.getTeamNum());
		
	return island.centerBlock;
}
