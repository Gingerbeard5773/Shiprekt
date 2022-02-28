void onInit(CBlob@ this)
{
	this.Tag("decoyCore");
	
	this.set_f32("weight", 6.0f);

	if (isClient())
	{
		//add an additional frame to the damage frames animation
		CSprite@ sprite = this.getSprite();
		Animation@ animation = sprite.getAnimation("default");
		if (animation !is null)
		{
			array<int> frames = {3};
			animation.AddFrames(frames);
		}
	}
}
