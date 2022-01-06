#include "BlockHooks.as";
void onInit(CBlob@ this)
{
	this.Tag("platform");
	
	this.set_u16("cost", 15);
	this.set_f32("weight", 0.2f);
	
	BlockHooks@ blockHooks;
	this.get("BlockHooks", @blockHooks);
	blockHooks.addHook("onBlockPlaced", @onBlockPlaced); //add onBlockPlaced hook
}

void onBlockPlaced(CBlob@ this) //activate when the block is placed
{
	CBlob@[] overlapping;
	this.getOverlapping(@overlapping);
	
	//SCUFFED CODE BELOW!! please redo it for me if you want LOL
	
	//this is for changing the frame of the platform touching a core, made difficult due to shit rotation problems and different sprite frames.
	//probably would be much easier if only 1 'special' frame was used instead of the 4, & if I wasn't brain dead.
	
	for (uint i = 0; i < overlapping.length; i++)
	{
		CBlob@ b = overlapping[i];
		if (b.hasTag("core"))
		{
			//just start from the beginning if you want to redo it, dont use this shite code
			Vec2f dif = b.getPosition() - this.getPosition();
			Vec2f angle = Vec2f(dif.x, dif.y).RotateBy(-b.getAngleDegrees(), Vec2f());
			angle = Vec2f(Maths::Round(angle.x), Maths::Round(angle.y)); //equalize
			//print(dif+" : "+angle+" : "+ b.getAngleDegrees());
			
			//use vector to see which side of the core we are on (could do angle instead?)
			CSprite@ sprite = this.getSprite();
			if (angle == Vec2f(8, 0)) //left
			{
				sprite.SetFrame(5);
				this.setAngleDegrees(-dif.Angle()); //set angle to properly place frame
			}
			else if (angle == Vec2f(0, 8)) //top
			{
				sprite.SetFrame(2);
				this.setAngleDegrees(-dif.Angle() - 90);
			}
			else if (angle == Vec2f(0, -8) || angle == Vec2f(0, -7)) //bottom, why -7? :(
			{
				sprite.SetFrame(4);
				this.setAngleDegrees(-dif.Angle() + 90);
			}
			else if (angle == Vec2f(-8, 0) || angle == Vec2f(-7, 0)) //right
			{
				sprite.SetFrame(3);
				this.setAngleDegrees(-dif.Angle() + 180);
			}
		}
	}
}
