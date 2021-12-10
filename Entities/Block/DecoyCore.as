#include "TeamColour.as"
#include 'DestructCommon.as';

const float INITIAL_HEALTH = 4.0f;

void onInit(CBlob@ this)
{
	this.Tag('decoyCore');
	//this.set_bool("placed", false);
	//this.Sync("placed", true);

	if (isServer())
	{
		this.server_SetHealth(INITIAL_HEALTH);
	}

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ layer = sprite.addSpriteLayer('damage');

		if (layer !is null)
		{
			layer.SetRelativeZ(1);
			layer.SetLighting(false);
			Animation@ animation = layer.addAnimation('default', 0, false);
			array<int> frames = {97, 99, 100, 101};
			animation.AddFrames(frames);
			layer.SetAnimation('default');
		}

		updateFrame(this);
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
	CSpriteLayer@ layer = sprite.getSpriteLayer('damage');
	uint8 frames = layer.animation.getFramesCount();
	uint8 step = frames - ((health / INITIAL_HEALTH) * frames);
	layer.animation.frame = step;
}
