//Block damage frames
//NOTICE: put this script before the block's script in the CFG if the block adds more frames in it's onInit

#include "MakeDustParticle.as";

void onInit(CBlob@ this)
{
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		Animation@ animation = sprite.addAnimation("default", 0, false);
		array<int> frames = {0, 1, 2}; //blocks require atleast three frames
		animation.AddFrames(frames);
		sprite.SetAnimation("default");

		updateFrame(this);
	}
}

void onHealthChange(CBlob@ this, float old)
{
	if (isClient())
	{
		updateFrame(this);
	}
}

void updateFrame(CBlob@ this)
{
	float health = this.getHealth();

	CSprite@ sprite = this.getSprite();
	if (sprite.animation is null) return; //not required

	uint8 frames = sprite.animation.getFramesCount();
	uint8 step = frames - ((health / this.getInitialHealth()) * frames);
	
	if (sprite.animation.frame < step)
	{
		if (!v_fastrender)
		{
			for (int i = 0; i < 2; ++i) //wood chips on frame change
			{
				CParticle@ p = makeGibParticle("Woodparts", this.getPosition(), getRandomVelocity(0, 0.3f, XORRandom(360)),
												0, XORRandom(6), Vec2f(8, 8), 0.0f, 0, "");
				if (p !is null)
				{
					//p.Z = 550.0f;
					p.damping = 0.98f;
				}
			}
			
			MakeDustParticle(this.getPosition(), "/dust2.png");
		}
	}

	sprite.animation.frame = step;
}
