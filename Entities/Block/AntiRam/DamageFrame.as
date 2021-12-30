//Block damage frames
//NOTICE: put this script before the block's script in the CFG if the block adds more frames in it's onInit
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
	sprite.animation.frame = step;
}
