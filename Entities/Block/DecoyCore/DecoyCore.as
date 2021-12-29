
void onInit(CBlob@ this)
{
	this.Tag("decoyCore");
	this.set_bool("placed", false);
	//this.Sync("placed", true);

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

void onTick(CBlob@ this)
{
	if (this.getShape().getVars().customData <= 0)//not placed yet
		return;

	if (!this.get_bool("placed"))
	{
		CRules@ rules = getRules();
		if (!rules.exists("decoyCoreCount" + this.getTeamNum()))
		{
			rules.set_u8("decoyCoreCount" + this.getTeamNum(), 0);
			rules.Sync("decoyCoreCount" + this.getTeamNum(), true);
		}

		rules.set_u8("decoyCoreCount" + this.getTeamNum(), rules.get_u8("decoyCoreCount" + this.getTeamNum()) + 1);
		rules.Sync("decoyCoreCount" + this.getTeamNum(), true);
		
		this.set_bool("placed", true);
	}
}
