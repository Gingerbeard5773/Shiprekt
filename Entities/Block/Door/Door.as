//trap block script for devious builders
#include "IslandsCommon.as"
#include "HumanCommon.as"
#include "BlockCommon.as"
#include "BlockProduction.as"
#include "Hitters.as"
#include "MapFlags.as"
#include "DoorCommon.as"


void onInit( CBlob@ this )
{
    this.set_bool("open", false);  
    this.getShape().SetRotationsAllowed(false);
	this.Tag("door");
	this.getShape().getConsts().collidable = true;

	CSprite@ sprite = this.getSprite();
    if(sprite !is null)
    {
        //default
        {
            Animation@ anim = sprite.addAnimation("default", 0, false);
            anim.AddFrame(Block::DOOR);
        }
        //folding
        {
            Animation@ anim = sprite.addAnimation("open", 2, false);

            int[] frames = { Block::DOOR, Block::DOOR+1, Block::DOOR+2 };

            anim.AddFrames(frames);
        }
    }
}


bool isOpen( CBlob@ this )
{
	return !this.getShape().getConsts().collidable;
}

void setOpen( CBlob@ this, bool open, bool faceLeft = false)
{
	CSprite@ sprite = this.getSprite();

	if (open)
	{
       sprite.SetAnimation( "open" );//update sprite
		this.getCurrentScript().tickFrequency = 3;
		this.getShape().getConsts().collidable = false;
		sprite.SetFacingLeft(faceLeft);   // swing left or right
		Sound::Play("/DoorOpen.ogg", this.getPosition());
	}
	else
	{
       sprite.SetAnimation( "default" );//update sprite
		this.getCurrentScript().tickFrequency = 0;
		this.getShape().getConsts().collidable = true;
		Sound::Play("/DoorClose.ogg", this.getPosition());
	}
	
}




bool canClose(CBlob@ this)
{
	const uint count = this.getTouchingCount();
	uint collided = 0;
	for (uint step = 0; step < count; ++step)
	{
		CBlob@ blob = this.getTouchingByIndex(step);
		if (blob.getName() == "human")
		{
			collided++;
		}
	}
	return collided == 0;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		this.getCurrentScript().tickFrequency = 3;
	}
}

void onEndCollision(CBlob@ this, CBlob@ blob)
{
	if (blob !is null)
	{
		if (canClose(this))
		{
			if (isOpen(this))
			{
				setOpen(this, false);
			}
			this.getCurrentScript().tickFrequency = 0;
		}
	}
}


bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (isOpen(this))
		return false;

	if (canOpenDoor(this, blob))
	{
		Vec2f pos = this.getPosition();
		Vec2f other_pos = blob.getPosition();
		Vec2f direction = Vec2f(1, 0);
		direction.RotateBy(this.getAngleDegrees());
		setOpen(this, true, ((pos - other_pos) * direction) < 0.0f);
		return false;
	}
	return true;
}
