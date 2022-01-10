#include "AccurateSoundPlay.as";
#include "IslandsCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("piston");
    this.Tag("solid");
	
	this.set_u16("cost", 50);
	this.set_f32("weight", 0.85f);
	this.set_bool("toggled", false);

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
		
		if (canMoveBlocks(this, this))
		{
			moveBlocks(this, this);
		}
		
		if (!this.get_bool("toggled"))
		{
			Vec2f[] points = {Vec2f(2, 0), Vec2f(6, 0), Vec2f(6, -8), Vec2f(2, -8)};
			shape.AddShape(points);
			directionalSoundPlay("DispenserFire.ogg", this.getPosition());
			sprite.SetFrame(1);
			this.set_bool("toggled", true);
		}
		else
		{
			shape.RemoveShape(1);
			directionalSoundPlay("LoadingTick2.ogg", this.getPosition());
			sprite.SetFrame(0);
			this.set_bool("toggled", false);
		}
    }
}

bool canMoveBlocks(CBlob@ this, CBlob@ piston, u16 counter = 0)
{
	Vec2f aimVector = Vec2f(1, 0).RotateBy(piston.getAngleDegrees() - 90);
	HitInfo@[] hitInfos;
	f32 toggleFactor = (this.hasTag("piston") && this.get_bool("toggled") ? 8.0f : 0.0f); //add distance to ray if we are toggled on
	if (getMap().getHitInfosFromRay(this.getPosition() + Vec2f(5 + toggleFactor, 0).RotateBy(-aimVector.Angle()), -aimVector.Angle(), 5.0f, this, @hitInfos))
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			CBlob@ b = hitInfos[i].blob;
			if (b is null || !b.hasTag("block")) continue;
			
			if (counter >= 10) return false;
			
			return canMoveBlocks(b, piston, counter + 1);
		}
	}
	return counter < 10;
}

void moveBlocks(CBlob@ this, CBlob@ piston)
{
	Vec2f aimVector = Vec2f(1, 0).RotateBy(piston.getAngleDegrees() - 90);
	if (piston is this && this.get_bool("toggled")) //stop move process if a new block appeared at piston front
	{
		CBlob@[] blobs;
		getMap().getBlobsAtPosition(this.getPosition() + Vec2f(5 ,0).RotateBy(-aimVector.Angle()), @blobs);
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			if (blob is this) continue;
			
			if (blob.hasTag("block")) return;
		}
	}
	
	HitInfo@[] hitInfos;
	f32 toggleFactor = (this.hasTag("piston") && this.get_bool("toggled") ? 8.0f : 0.0f); //add distance to ray if we are toggled on
	if (getMap().getHitInfosFromRay(this.getPosition() + Vec2f(5 + toggleFactor,0).RotateBy(-aimVector.Angle()), -aimVector.Angle(), 5.0f, this, @hitInfos))
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			CBlob@ b = hitInfos[i].blob;
			if (b is null) continue;
			
			Island@ island = getIsland(b);
			if (island !is null)
			{
				for (uint i = 0; i < island.blocks.length; ++i)
				{
					IslandBlock@ isle_block = island.blocks[i];
					CBlob@ block = getBlobByNetworkID(isle_block.blobID);
					if (block is null || block !is b) continue;
					
					if (block.getShape().getVars().customData == this.getShape().getVars().customData)
					{
						moveBlocks(b, piston); //repeat until end is reached
						
						Vec2f movePos = Vec2f(0, -8 * (piston.get_bool("toggled") ? -1 : 1)).RotateBy(piston.getAngleDegrees() - island.angle);
						isle_block.offset += movePos;
					}
				}
			}
		}
	}
}