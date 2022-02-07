//trap block script for devious builders
#include "AccurateSoundPlay.as";

void onInit(CBlob@ this)
{
	this.Tag("door");
	
	this.set_f32("weight", 1.0f);
	
    this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().collidable = true;

	CSprite@ sprite = this.getSprite();
    if (sprite !is null)
    {
        //default
        {
            Animation@ anim = sprite.addAnimation("default", 0, false);
            anim.AddFrame(0);
        }
        //folding
        {
            Animation@ anim = sprite.addAnimation("open", 2, false);
            int[] frames = {0, 1};
            anim.AddFrames(frames);
        }
    }
}

bool isOpen(CBlob@ this)
{
	return !this.getShape().getConsts().collidable;
}

void setOpen(CBlob@ this, bool open, bool faceLeft = false)
{
	CSprite@ sprite = this.getSprite();

	if (open)
	{
        sprite.SetAnimation("open");//update sprite
		this.getCurrentScript().tickFrequency = 3;
		this.getShape().getConsts().collidable = false;
		sprite.SetFacingLeft(faceLeft);   // swing left or right
		directionalSoundPlay("/DoorOpen.ogg", this.getPosition());
	}
	else
	{
        sprite.SetAnimation("default");//update sprite
		this.getCurrentScript().tickFrequency = 0;
		this.getShape().getConsts().collidable = true;
		directionalSoundPlay("/DoorClose.ogg", this.getPosition());
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

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (isOpen(this))
		return false;

	if (blob.getShape().getConsts().collidable && //can collide
		this.getTeamNum() == blob.getTeamNum() && //is same team
		blob.hasTag("player"))                    //is human
	{
		Vec2f direction = Vec2f(1, 0);
		direction.RotateBy(this.getAngleDegrees());
		setOpen(this, true, ((this.getPosition() - blob.getPosition()) * direction) < 0.0f);
		return false;
	}
	return true;
}
